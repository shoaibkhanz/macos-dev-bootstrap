### Pydantic AI Agent with Tools and Dependency Injection for Structured Output

Source: https://github.com/pydantic/pydantic-ai/blob/main/README.md

This comprehensive example showcases how to build a Pydantic AI agent for a specific domain, such as a bank support system, using advanced features. It demonstrates defining custom dependencies with `dataclass`, enforcing structured output with `BaseModel`, and utilizing dependency injection via `RunContext` for dynamic instructions and tool registration. This approach ensures type safety and modularity in complex agent designs.

```python
from dataclasses import dataclass

from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext

from bank_database import DatabaseConn


# SupportDependencies is used to pass data, connections, and logic into the model that will be needed when running
# instructions and tool functions. Dependency injection provides a type-safe way to customise the behavior of your agents.
@dataclass
class SupportDependencies:
    customer_id: int
    db: DatabaseConn


# This Pydantic model defines the structure of the output returned by the agent.
class SupportOutput(BaseModel):
    support_advice: str = Field(description='Advice returned to the customer')
    block_card: bool = Field(description="Whether to block the customer's card")
    risk: int = Field(description='Risk level of query', ge=0, le=10)


# This agent will act as first-tier support in a bank.
# Agents are generic in the type of dependencies they accept and the type of output they return.
# In this case, the support agent has type `Agent[SupportDependencies, SupportOutput]`.
support_agent = Agent(
    'openai:gpt-5.2',
    deps_type=SupportDependencies,
    # The response from the agent will, be guaranteed to be a SupportOutput,
    # if validation fails the agent is prompted to try again.
    output_type=SupportOutput,
    instructions=(
        'You are a support agent in our bank, give the '
        'customer support and judge the risk level of their query.'
    ),
)


# Dynamic instructions can make use of dependency injection.
# Dependencies are carried via the `RunContext` argument, which is parameterized with the `deps_type` from above.
# If the type annotation here is wrong, static type checkers will catch it.
@support_agent.instructions
async def add_customer_name(ctx: RunContext[SupportDependencies]) -> str:
    customer_name = await ctx.deps.db.customer_name(id=ctx.deps.customer_id)
    return f"The customer's name is {customer_name!r}"


# The `tool` decorator let you register functions which the LLM may call while responding to a user.
# Again, dependencies are carried via `RunContext`, any other arguments become the tool schema passed to the LLM.
```

--------------------------------

### Implement a Bank Support Agent with Pydantic AI

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/index.md

This code demonstrates how to build a bank support agent using Pydantic AI. It showcases defining agent dependencies, structured output, static and dynamic instructions, and registering tools for database interaction. The agent is configured to use an OpenAI model and can run queries, returning validated responses.

```python
from dataclasses import dataclass

from pydantic import BaseModel, Field
from pydantic_ai import Agent, RunContext

from bank_database import DatabaseConn


@dataclass
class SupportDependencies:
    customer_id: int
    db: DatabaseConn


class SupportOutput(BaseModel):
    support_advice: str = Field(description='Advice returned to the customer')
    block_card: bool = Field(description="Whether to block the customer's card")
    risk: int = Field(description='Risk level of query', ge=0, le=10)


support_agent = Agent(
    'openai:gpt-5.2',
    deps_type=SupportDependencies,
    output_type=SupportOutput,
    instructions=(
        'You are a support agent in our bank, give the '
        'customer support and judge the risk level of their query.'
    ),
)


@support_agent.instructions
async def add_customer_name(ctx: RunContext[SupportDependencies]) -> str:
    customer_name = await ctx.deps.db.customer_name(id=ctx.deps.customer_id)
    return f"The customer's name is {customer_name!r}"


@support_agent.tool
async def customer_balance(
    ctx: RunContext[SupportDependencies], include_pending: bool
) -> float:
    """Returns the customer's current account balance."""
    return await ctx.deps.db.customer_balance(
        id=ctx.deps.customer_id,
        include_pending=include_pending,
    )


...


async def main():
    deps = SupportDependencies(customer_id=123, db=DatabaseConn())
    result = await support_agent.run('What is my balance?', deps=deps)
    print(result.output)
    """
    support_advice='Hello John, your current account balance, including pending transactions, is $123.45.' block_card=False risk=1
    """

    result = await support_agent.run('I just lost my card!', deps=deps)
    print(result.output)
    """
    support_advice="I'm sorry to hear that, John. We are temporarily blocking your card to prevent unauthorized transactions." block_card=True risk=8
    """
```

--------------------------------

### RunContext and Dependencies

Source: https://github.com/pydantic/pydantic-ai/blob/main/README.md

The RunContext object passed to tools contains the agent's state and dependencies. It provides access to the dependency object through ctx.deps, allowing tools to access databases, services, and other resources.

```APIDOC
## RunContext[T]

### Description
Context object passed to tool functions containing agent state and dependencies. Provides type-safe access to the dependency object and agent execution context.

### Properties
#### Context Properties
- **deps** (T) - The dependency object of generic type T containing services and data
- **customer_id** (accessible via ctx.deps) - Example: customer identifier from dependencies

### Usage Example
```python
class SupportDependencies:
    customer_id: int
    db: DatabaseConn

async def customer_balance(
        ctx: RunContext[SupportDependencies], include_pending: bool
) -> float:
    # Access dependencies through ctx.deps
    balance = await ctx.deps.db.customer_balance(
        id=ctx.deps.customer_id,
        include_pending=include_pending,
    )
    return balance
```

### Notes
- RunContext is generic and typed with the dependency class
- Provides type safety for accessing dependencies
- Available to all tool functions decorated with @agent.tool
```

--------------------------------

### Implement Dependency Injection in PydanticAI Agents

Source: https://context7.com/pydantic/pydantic-ai/llms.txt

Demonstrates how to define custom dependencies using dataclasses and access them within system prompts and tools using RunContext. This approach allows for secure handling of API keys and shared resources like HTTP clients.

```python
from dataclasses import dataclass
import httpx
from pydantic_ai import Agent, RunContext


@dataclass
class MyDeps:
    api_key: str
    http_client: httpx.AsyncClient


agent = Agent(
    'openai:gpt-5.2',
    deps_type=MyDeps,
)


@agent.system_prompt
async def get_system_prompt(ctx: RunContext[MyDeps]) -> str:
    response = await ctx.deps.http_client.get(
        'https://example.com',
        headers={'Authorization': f'Bearer {ctx.deps.api_key}'},
    )
    response.raise_for_status()
    return f'System context: {response.text}'


@agent.tool
async def fetch_data(ctx: RunContext[MyDeps], query: str) -> str:
    """Fetch data from external API."""
    response = await ctx.deps.http_client.get(
        'https://api.example.com/data',
        params={'q': query},
        headers={'Authorization': f'Bearer {ctx.deps.api_key}'},
    )
    return response.text


async def main():
    async with httpx.AsyncClient() as client:
        deps = MyDeps('api-key-here', client)
        result = await agent.run('Search for Python tutorials', deps=deps)
        print(result.output)
```

--------------------------------

### Access dependencies via RunContext in system prompts

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/dependencies.md

Use RunContext parameterized with your dependency type to access injected services and data. Access the dependency instance through the .deps attribute.

```python
from dataclasses import dataclass

import httpx

from pydantic_ai import Agent, RunContext


@dataclass
class MyDeps:
    api_key: str
    http_client: httpx.AsyncClient


agent = Agent(
    'openai:gpt-5.2',
    deps_type=MyDeps,
)


@agent.system_prompt  # (1)!
async def get_system_prompt(ctx: RunContext[MyDeps]) -> str:  # (2)!
    response = await ctx.deps.http_client.get(  # (3)!
        'https://example.com',
        headers={'Authorization': f'Bearer {ctx.deps.api_key}'},  # (4)!
    )
    response.raise_for_status()
    return f'Prompt: {response.text}'


async def main():
    async with httpx.AsyncClient() as client:
        deps = MyDeps('foobar', client)
        result = await agent.run('Tell me a joke.', deps=deps)
        print(result.output)
        #> Did you hear about the toothpaste scandal? They called it Colgate.
```
