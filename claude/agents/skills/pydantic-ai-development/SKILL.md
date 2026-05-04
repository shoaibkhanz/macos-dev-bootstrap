---
name: pydantic-ai-development
description: >
  Building agents, workflows, and evals with the PydanticAI ecosystem (pydantic-ai, pydantic-graph, pydantic-evals).
  Use when creating agents with tools and structured outputs, building graph-based workflows with state machines
  and human-in-the-loop, writing MCP servers, or designing LLM-as-judge evaluation metrics.
---

# PydanticAI Development

Comprehensive guide for building production-grade agentic systems with the PydanticAI ecosystem.

## Ecosystem Overview

| Package | Purpose | Install |
|---------|---------|---------|
| `pydantic-ai` | Agent framework: tools, deps, structured output, model abstraction | `pip install pydantic-ai` |
| `pydantic-graph` | State machine workflows: nodes, transitions, human-in-the-loop | `pip install pydantic-graph` |
| `pydantic-evals` | Evaluation: datasets, cases, LLM-as-judge metrics | `pip install pydantic-evals` |
| `pydantic-settings` | Typed config from `.env` files | `pip install pydantic-settings` |
| `fastmcp` | MCP server framework | `pip install fastmcp` |

---

## 1. Agent Architecture

### 1.1 Agent Factory Pattern

Always create agents via factory functions — never as module-level globals with hardcoded config.

```python
from dataclasses import dataclass
from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext
from pydantic_ai.models.anthropic import AnthropicModel
from pydantic_ai.providers.anthropic import AnthropicProvider


@dataclass
class MyDeps:
    """Dependencies injected into tools and instructions. Use dataclass, not dict."""
    conn: DatabaseConnection
    user_id: int


class MyOutput(BaseModel):
    """Structured output validated by pydantic. Prefer frozen=True for immutability."""
    summary: str
    confidence: float = Field(ge=0, le=1)
    action_items: list[str] | None = None


def create_my_agent(settings: Settings) -> Agent[MyDeps, MyOutput]:
    """Factory pattern: returns a fully configured agent."""
    model = AnthropicModel(
        "claude-sonnet-4-20250514",
        provider=AnthropicProvider(api_key=settings.anthropic_api_key),
    )

    agent = Agent(
        model=model,
        deps_type=MyDeps,
        output_type=MyOutput,
        instructions="You are a helpful assistant...",
    )

    # Register tools on the agent instance
    @agent.tool
    def lookup(ctx: RunContext[MyDeps], item_id: int) -> str:
        """Tool docstring becomes the tool description for the LLM."""
        result = query_db(ctx.deps.conn, item_id)
        return json.dumps(result)  # Always return str from tools

    return agent
```

### 1.2 Dependencies (`RunContext`)

Dependencies flow through `RunContext[DepsType]` — the DI mechanism for tools and dynamic instructions.

**Rules:**
- Define deps as a `@dataclass` (not dict, not BaseModel)
- Put DB connections, API clients, config, user context in deps
- Tools access deps via `ctx.deps`
- The `deps_type=` parameter exists solely for static type checking
- Pass deps at runtime: `agent.run("prompt", deps=my_deps)`

```python
@dataclass
class SupportDeps:
    customer_id: int
    db: DatabaseConn
    http_client: httpx.AsyncClient  # share clients via deps


# Dynamic instructions can use deps
@agent.instructions
async def add_context(ctx: RunContext[SupportDeps]) -> str:
    name = await ctx.deps.db.customer_name(ctx.deps.customer_id)
    return f"Customer name: {name}"
```

### 1.3 Tools

**Design principle:** Tools should be thin wrappers around pure functions. Keep business logic in testable functions, not inside tool decorators.

```python
# tools.py — pure functions, independently testable
def get_employee(conn: Connection, employee_id: int) -> dict | None:
    row = conn.execute("SELECT ...", (employee_id,)).fetchone()
    return dict(row) if row else None

# agents.py — thin wrappers that call pure functions
@agent.tool
def employee_lookup(ctx: RunContext[MyDeps], employee_id: int) -> str:
    """Look up employee profile and current metrics."""
    result = get_employee(ctx.deps.conn, employee_id)
    return json.dumps(result)  # Tools MUST return str
```

**Tool rules:**
- Tool return type must be `str` (use `json.dumps` for structured data)
- Docstring = tool description shown to the LLM — make it clear and specific
- Tool parameters (besides `ctx`) become the tool's JSON schema
- Use `Optional` / default values for optional parameters
- Tools can be `async` — useful for HTTP calls, DB async drivers

### 1.4 Structured Output

```python
# Simple: single output type
agent = Agent(model, output_type=MyOutput)

# Union: agent chooses which type to return
agent = Agent(model, output_type=SuccessResult | FailureResult)

# List notation (better type-checker compat):
agent = Agent(model, output_type=[Box, str])

# Output functions (tool-like, runs code):
agent = Agent(model, output_type=[run_sql_query, SQLFailure])
```

If validation fails, pydantic-ai automatically retries (controlled by `retries=` parameter, default 1).

### 1.5 Instructions vs System Prompt

```python
# Static instructions (preferred — supports template variables)
agent = Agent(model, instructions="You are a support agent...")

# Dynamic instructions (use deps at runtime)
@agent.instructions
async def dynamic(ctx: RunContext[MyDeps]) -> str:
    return f"Current user: {ctx.deps.user_id}"

# Legacy: system_prompt (still works, same effect)
agent = Agent(model, system_prompt="You are...")
```

### 1.6 Running Agents

```python
# Async (preferred)
result = await agent.run("user prompt", deps=deps)
print(result.output)       # typed as MyOutput
print(result.all_messages())  # full conversation history

# Sync (convenience)
result = agent.run_sync("prompt", deps=deps)

# Streaming
async with agent.run_stream("prompt", deps=deps) as stream:
    async for chunk in stream.stream_text():
        print(chunk, end="")
```

### 1.7 Model Configuration

```python
# String shorthand
agent = Agent("anthropic:claude-sonnet-4-20250514")
agent = Agent("openai:gpt-5.2")
agent = Agent("google-gla:gemini-2.5-flash")

# Explicit model object (for custom providers, API keys)
from pydantic_ai.models.anthropic import AnthropicModel
from pydantic_ai.providers.anthropic import AnthropicProvider
model = AnthropicModel(
    "claude-sonnet-4-20250514",
    provider=AnthropicProvider(api_key=settings.api_key),
)

# Override model at runtime
result = await agent.run("prompt", model="openai:gpt-5-mini", deps=deps)
```

---

## 2. Pydantic Graph (Workflows)

### 2.1 Core Concepts

Pydantic Graph models workflows as **typed state machines**: nodes are dataclasses, transitions are return type hints, and state flows via `GraphRunContext`.

```python
from __future__ import annotations  # REQUIRED for forward references
from dataclasses import dataclass
from pydantic_graph import BaseNode, End, Graph, GraphRunContext
```

### 2.2 Node Definition

```python
# BaseNode[StateType, DepsType, ReturnType]
# - StateType: shared state (or None)
# - DepsType: dependency injection (or None)  
# - ReturnType: what End() returns (or None)

@dataclass
class GatherContext(BaseNode[CoachingState, None, CoachingResult]):
    query: str

    async def run(self, ctx: GraphRunContext[CoachingState]) -> Analyse:
        # Access/modify shared state
        ctx.state.context = fetch_data(self.query)
        # Return next node (transition)
        return Analyse()


@dataclass
class Analyse(BaseNode[CoachingState, None, CoachingResult]):
    async def run(self, ctx: GraphRunContext[CoachingState]) -> Recommend | End[CoachingResult]:
        if not ctx.state.context:
            return End(CoachingResult(error="No data"))
        ctx.state.analysis = analyze(ctx.state.context)
        return Recommend()
```

### 2.3 State Design

```python
@dataclass
class CoachingState:
    """Mutable state that flows through the graph."""
    query: str
    employee_id: int | None = None
    context: dict | None = None
    analysis: str | None = None
    recommendations: list[str] | None = None
    feedback: str | None = None
    revision_count: int = 0
```

**Rules:**
- State is mutable — nodes modify it via `ctx.state`
- Keep state flat — avoid deep nesting
- Include counters for loop guards (`revision_count`)
- State should contain data, not behavior

### 2.4 Common Patterns

**Sequential Pipeline:**
```
GatherContext → Analyse → Recommend → End
```

**Evaluator-Optimizer Loop (from course lesson 23):**
```
Write → Review → Revise → Review → ... → End
```
```python
@dataclass
class Review(BaseNode[State, None, Article]):
    async def run(self, ctx: GraphRunContext[State]) -> Revise | End[Article]:
        reviews = evaluate(ctx.state.article)
        if reviews.score > 0.8 or ctx.state.revision_count >= MAX_REVISIONS:
            return End(ctx.state.article)
        ctx.state.reviews = reviews
        return Revise()

@dataclass
class Revise(BaseNode[State, None, Article]):
    async def run(self, ctx: GraphRunContext[State]) -> Review:
        ctx.state.article = rewrite(ctx.state.article, ctx.state.reviews)
        ctx.state.revision_count += 1
        return Review()
```

**Human-in-the-Loop:**
```python
from pydantic_graph.persistence.file import FileStatePersistence

@dataclass  
class HumanReview(BaseNode[State, None, Result]):
    async def run(self, ctx: GraphRunContext[State]) -> Revise | End[Result]:
        # Graph pauses here — use persistence to resume later
        if ctx.state.feedback is None:
            return End(Result(needs_input=True))  # Signal: waiting for human
        if ctx.state.feedback == "approved":
            return End(Result(approved=True))
        return Revise()

# Running with persistence
persistence = FileStatePersistence(Path("graph_state.json"))
persistence.set_graph_types(my_graph)

async with my_graph.iter(start_node, state=state, persistence=persistence) as run:
    while True:
        node = await run.next()
        if isinstance(node, End):
            break
```

### 2.5 Building and Running Graphs

```python
# Define the graph with all node types
coaching_graph = Graph(nodes=[GatherContext, Analyse, Recommend, HumanReview, Revise])

# Run synchronously
result = coaching_graph.run_sync(GatherContext(query="How is Marcus doing?"))
print(result.output)

# Run async
result = await coaching_graph.run(GatherContext(query="..."), state=CoachingState())

# Generate Mermaid diagram
print(coaching_graph.mermaid_code(start_node=GatherContext))

# Iterate step-by-step (for logging, debugging)
async with coaching_graph.iter(GatherContext(query="..."), state=state) as run:
    while True:
        node = await run.next()
        print(f"Now at: {type(node).__name__}")
        if isinstance(node, End):
            break
```

---

## 3. Testing

### 3.1 Prevent Accidental Real API Calls

```python
# conftest.py — add this FIRST
from pydantic_ai import models
models.ALLOW_MODEL_REQUESTS = False  # Fails if any test hits a real API
```

### 3.2 TestModel (Simple Mocking)

```python
from pydantic_ai.models.test import TestModel

async def test_my_agent():
    with my_agent.override(model=TestModel()):
        result = await my_agent.run("test prompt", deps=deps)
        assert result.output == "success (no tool calls)"

    # Custom output
    with my_agent.override(model=TestModel(custom_output_text="custom response")):
        result = await my_agent.run("test", deps=deps)

    # TestModel auto-generates structured output matching the schema
    # For output_type=MyModel, it fills fields with schema-based defaults
```

### 3.3 FunctionModel (Full Control)

```python
from pydantic_ai.models.function import FunctionModel, AgentInfo
from pydantic_ai import ModelMessage, ModelResponse, TextPart, ToolCallPart

def mock_model(messages: list[ModelMessage], info: AgentInfo) -> ModelResponse:
    """Full control over what the 'model' returns."""
    if len(messages) == 1:
        # First call: make a tool call
        return ModelResponse(parts=[
            ToolCallPart("employee_lookup", {"employee_id": 1})
        ])
    else:
        # After tool result: return text
        return ModelResponse(parts=[TextPart("Based on the data...")])

async def test_tool_flow():
    with agent.override(model=FunctionModel(mock_model)):
        result = await agent.run("How is Marcus?", deps=deps)
```

### 3.4 Testing Tools Directly

Tools are pure functions — test them without the agent:

```python
# test_tools.py
def test_get_employee(conn):
    result = get_employee(conn, employee_id=1)
    assert result is not None
    assert result["name"] == "Sarah Chen"
    assert "avg_aht" in result

def test_get_employee_not_found(conn):
    result = get_employee(conn, employee_id=999)
    assert result is None
```

### 3.5 Capture Messages for Assertions

```python
from pydantic_ai import capture_run_messages

async def test_agent_calls_right_tools():
    with capture_run_messages() as messages:
        with agent.override(model=TestModel()):
            await agent.run("Show team overview", deps=deps)

    # Inspect what tools were called
    tool_calls = [
        part for msg in messages
        for part in getattr(msg, 'parts', [])
        if hasattr(part, 'tool_name')
    ]
    assert any(tc.tool_name == "team_overview" for tc in tool_calls)
```

---

## 4. Evaluation (Pydantic Evals)

### 4.1 Dataset-Driven Evals

```python
from pydantic_evals import Case, Dataset

dataset = Dataset(
    name="coaching_agent_eval",
    cases=[
        Case(
            name="team_overview_request",
            inputs="Show me the team overview",
            expected_output="summary with all 5 agents ranked by AHT",
        ),
        Case(
            name="employee_lookup",
            inputs="How is Marcus doing?",
            expected_output="Marcus's AHT trends and coaching goals",
        ),
    ],
)

# Run evals
report = dataset.evaluate_sync(my_agent_function)
```

### 4.2 LLM-as-Judge Pattern

Use a second model to score the primary model's output:

```python
from pydantic import BaseModel, Field
from pydantic_ai import Agent

class QualityScore(BaseModel):
    uses_data: int = Field(ge=0, le=1, description="Did the response cite specific data?")
    actionable: int = Field(ge=0, le=1, description="Are recommendations specific and actionable?")
    accurate: int = Field(ge=0, le=1, description="Is the analysis factually correct given the data?")
    reason: str

judge_agent = Agent(
    "anthropic:claude-sonnet-4-20250514",
    output_type=QualityScore,
    instructions="""You are an evaluation judge. Score the agent's coaching response
    against the provided criteria. Be strict — only score 1 if clearly met.""",
)

async def evaluate_response(query: str, response: str, context: str) -> QualityScore:
    prompt = f"""
    Query: {query}
    Available Data: {context}
    Agent Response: {response}
    
    Score this response.
    """
    result = await judge_agent.run(prompt)
    return result.output
```

### 4.3 Section-Level Scoring (Course Pattern)

For complex outputs, score per-section then aggregate per-dimension:

```python
class CriterionScore(BaseModel):
    score: int = Field(ge=0, le=1, description="Binary: meets criterion or not")
    reason: str

class SectionScores(BaseModel):
    content: CriterionScore
    actionability: CriterionScore
    data_grounding: CriterionScore

class EvalResult(BaseModel):
    sections: list[SectionScores]

    def aggregate(self) -> dict[str, float]:
        """Average each dimension across sections."""
        dims = {}
        for field in SectionScores.model_fields:
            scores = [getattr(s, field).score for s in self.sections]
            dims[field] = sum(scores) / len(scores) if scores else 0
        return dims
```

### 4.4 CI Integration

Run evals as pytest tests for regression:

```python
# test_evals.py
import pytest

@pytest.mark.slow
async def test_coaching_quality():
    result = await agent.run("How is Marcus doing?", deps=deps)
    score = await evaluate_response(
        query="How is Marcus doing?",
        response=result.output.summary,
        context=json.dumps(marcus_data),
    )
    assert score.uses_data == 1, f"Agent didn't use data: {score.reason}"
    assert score.actionable == 1, f"Not actionable: {score.reason}"
```

---

## 5. MCP Integration

### 5.1 Expose Agent as MCP Server

```python
from mcp.server.fastmcp import FastMCP
from pydantic_ai import Agent

server = FastMCP("Coaching Server")
coaching_agent = Agent("anthropic:claude-sonnet-4-20250514", instructions="...")

@server.tool()
async def coaching_advice(query: str) -> str:
    """Get coaching advice for a support team member."""
    result = await coaching_agent.run(query)
    return result.output

if __name__ == "__main__":
    server.run()
```

### 5.2 Use MCP Tools in Agent (Client)

```python
from pydantic_ai import Agent
from pydantic_ai.toolsets.fastmcp import FastMCPToolset

# Connect to remote MCP server
toolset = FastMCPToolset("http://localhost:8000/mcp")
agent = Agent("openai:gpt-5.2", toolsets=[toolset])

# Or from JSON config (multiple servers)
toolset = FastMCPToolset({
    "mcpServers": {
        "coaching": {"command": "python", "args": ["mcp_server.py"]},
        "search": {"command": "uvx", "args": ["mcp-search"]},
    }
})

# Or local FastMCP server (in-process)
toolset = FastMCPToolset(my_fastmcp_server)
agent = Agent("openai:gpt-5.2", toolsets=[toolset])
```

---

## 6. Settings Pattern

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    anthropic_api_key: str
    db_path: str = "app.db"
    max_retries: int = 3

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}
```

---

## 7. Project Structure (Recommended)

```
src/
├── models.py      # Pydantic models (frozen, with enums)
├── db.py          # Database connection, table creation
├── seed.py        # Synthetic data generation
├── tools.py       # Pure query functions (no agent dependency)
├── agents.py      # Agent factory + tool wrappers + CLI
├── settings.py    # Pydantic Settings
├── graph.py       # Pydantic Graph workflow (if using)
└── evals/
    ├── dataset.py   # Eval datasets and cases
    ├── metrics.py   # LLM-as-judge scoring
    └── run_eval.py  # Eval runner script

test/
├── conftest.py    # Shared fixtures, ALLOW_MODEL_REQUESTS = False
├── test_tools.py  # Unit tests for pure functions
├── test_agents.py # Agent tests with TestModel/FunctionModel
└── test_evals.py  # Eval regression tests
```

---

## 8. Common Mistakes

| Mistake | Fix |
|---------|-----|
| Tool returns `dict` | Tools must return `str`. Use `json.dumps(result)` |
| Global agent with hardcoded API key | Use factory function + Settings |
| Deps as a plain `dict` | Use `@dataclass` for type safety with `RunContext` |
| Testing with real API calls | Set `ALLOW_MODEL_REQUESTS = False`, use `TestModel` |
| Graph node modifies data not in state | All shared data must flow through `GraphRunContext.state` |
| Missing `from __future__ import annotations` | Required for forward-reference node transitions |
| Infinite revision loops | Add `revision_count` in state + max guard in Review node |
| BaseModel for deps | Use `@dataclass` — BaseModel creates unnecessary validation overhead |

---

## 9. Reference

For the latest API details, use Context7 or check the official docs:
- PydanticAI: https://ai.pydantic.dev
- Pydantic Graph: https://ai.pydantic.dev/graph/
- Pydantic Evals: https://ai.pydantic.dev/evals/
- FastMCP: https://gofastmcp.com

See [references/](references/) for additional cached documentation.
