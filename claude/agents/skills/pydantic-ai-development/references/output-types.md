### Extract Colors or Sizes with Pydantic AI Agent (Python)

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/output.md

This snippet initializes a `pydantic-ai` Agent configured to extract either a list of strings (colors) or a list of integers (sizes) from input text. It demonstrates the use of union types (`list[str] | list[int]`) for the agent's `output_type` and includes a `type: ignore` comment to address type-checking considerations when using unions directly in the `Agent` constructor. The agent is then run with different inputs to show its dynamic extraction capabilities.

```python
from pydantic_ai import Agent

agent = Agent[None, list[str] | list[int]](
    'openai:gpt-5-mini',
    output_type=list[str] | list[int],  # type: ignore # (1)!
    instructions='Extract either colors or sizes from the shapes provided.',
)

result = agent.run_sync('red square, blue circle, green triangle')
print(result.output)
# > ['red', 'blue', 'green']

result = agent.run_sync('square size 10, circle size 20, triangle size 30')
print(result.output)
# > [10, 20, 30]
```

--------------------------------

### Handle Union of Image and Text Output in Pydantic AI Agent

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/output.md

This Python example illustrates how to configure a Pydantic AI `Agent` to handle outputs that can be either an image (`BinaryImage`) or text (`str`) using a union type. It shows how the agent intelligently returns text when an image is not requested and returns a `BinaryImage` (with accompanying text in `result.response.text`) when an illustration is requested.

```python
from pydantic_ai import Agent, BinaryImage

agent = Agent('openai-responses:gpt-5.2', output_type=BinaryImage | str)

result = agent.run_sync('Tell me a two-sentence story about an axolotl, no image please.')
print(result.output)
"""
Once upon a time, in a hidden underwater cave, lived a curious axolotl named Pip who loved to explore. One day, while venturing further than usual, Pip discovered a shimmering, ancient coin that granted wishes!
"""

result = agent.run_sync('Tell me a two-sentence story about an axolotl with an illustration.')
assert isinstance(result.output, BinaryImage)
print(result.response.text)
"""
Once upon a time, in a hidden underwater cave, lived a curious axolotl named Pip who loved to explore. One day, while venturing further than usual, Pip discovered a shimmering, ancient coin that granted wishes!
"""
```

--------------------------------

### Initialize Feedback Agent with Union Output Type

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/graph.md

Creates a Pydantic AI agent using OpenAI's GPT model that evaluates emails and returns either feedback for revision or approval. Uses a union type (EmailRequiresWrite | EmailOk) to enable conditional routing based on the agent's decision.

```python
class EmailRequiresWrite(BaseModel):
    feedback: str


class EmailOk(BaseModel):
    pass


feedback_agent = Agent[None, EmailRequiresWrite | EmailOk](
    'openai:gpt-5.2',
    output_type=EmailRequiresWrite | EmailOk,  # type: ignore
    instructions=(
        'Review the email and provide feedback, email must reference the users specific interests.'
    ),
)
```

--------------------------------

### Create Agent with Output Functions and Multiple Output Types

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/output.md

Configures a Pydantic AI agent with multiple output types including a function and a Pydantic model. The agent uses output_type parameter to specify which functions or models the agent can call to produce final results.

```python
sql_agent = Agent[None, list[Row] | SQLFailure](
    'openai:gpt-5.2',
    output_type=[run_sql_query, SQLFailure],
    instructions='You are a SQL agent that can run SQL queries on a database.',
)
```

--------------------------------

### Create Agent with Multiple Output Types (Box or String)

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/output.md

Demonstrates creating an Agent that can return either a structured Box model or plain text string. The agent extracts box dimensions and validates that all required data is present before returning structured output. This example shows how to handle multiple output types using a list notation for better type checking compatibility.

```python
from pydantic import BaseModel

from pydantic_ai import Agent


class Box(BaseModel):
    width: int
    height: int
    depth: int
    units: str


agent = Agent(
    'openai:gpt-5-mini',
    output_type=[Box, str],
    instructions=(
        "Extract me the dimensions of a box, "
        "if you can't extract all data, ask the user to try again."
    ),
)

result = agent.run_sync('The box is 10x20x30')
print(result.output)
#> Please provide the units for the dimensions (e.g., cm, in, m).

result = agent.run_sync('The box is 10x20x30 cm')
print(result.output)
#> width=10 height=20 depth=30 units='cm'
```
