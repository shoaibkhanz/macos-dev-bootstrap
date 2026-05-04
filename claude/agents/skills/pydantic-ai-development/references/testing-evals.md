### Unit Test Pydantic-AI Agent with `TestModel` (Python)

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/testing.md

This Python unit test showcases how to effectively test a Pydantic-AI agent using `pydantic_ai.models.test.TestModel`. By overriding the agent's model with `TestModel`, the test can simulate tool calls and generate structured data based on the tool's schema, eliminating the need for complex mocking. It verifies the application's behavior by asserting against the stored forecast and the captured `ModelRequest` and `ToolCallPart` messages.

```python
from datetime import timezone
import pytest

from dirty_equals import IsNow, IsStr

from pydantic_ai import models, capture_run_messages, RequestUsage
from pydantic_ai.models.test import TestModel
from pydantic_ai import (
    ModelResponse,
    TextPart,
    ToolCallPart,
    ToolReturnPart,
    UserPromptPart,
    ModelRequest,
)

from fake_database import DatabaseConn
from weather_app import run_weather_forecast, weather_agent

pytestmark = pytest.mark.anyio
models.ALLOW_MODEL_REQUESTS = False


async def test_forecast():
    conn = DatabaseConn()
    user_id = 1
    with capture_run_messages() as messages:
        with weather_agent.override(model=TestModel()):
            prompt = 'What will the weather be like in London on 2024-11-28?'
            await run_weather_forecast([(prompt, user_id)], conn)

    forecast = await conn.get_forecast(user_id)
    assert forecast == '{"weather_forecast":"Sunny with a chance of rain"}'

    assert messages == [
        ModelRequest(
            parts=[
                UserPromptPart(
                    content='What will the weather be like in London on 2024-11-28?',
                    timestamp=IsNow(tz=timezone.utc),
                ),
            ],
            instructions='Providing a weather forecast at the locations the user provides.',
            timestamp=IsNow(tz=timezone.utc),
            run_id=IsStr(),
        ),
        ModelResponse(
            parts=[
                ToolCallPart(
                    tool_name='weather_forecast',
                    args={
                        'location': 'a',
                        'forecast_date': '2024-01-01',
                    },
                    tool_call_id=IsStr(),
                )
```

--------------------------------

### Unit Test Pydantic AI Agent with TestModel in Python

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/api/models/test.md

This Python snippet demonstrates how to use `pydantic_ai.models.test.TestModel` to unit test a `pydantic_ai.Agent`. It shows how to instantiate an agent, override its model with `TestModel` using a context manager, run a test, and assert the output and internal model request parameters. This setup is suitable for `pytest`.

```python
from pydantic_ai import Agent
from pydantic_ai.models.test import TestModel

my_agent = Agent('openai:gpt-5.2', instructions='...')


async def test_my_agent():
    """Unit test for my_agent, to be run by pytest."""
    m = TestModel()
    with my_agent.override(model=m):
        result = await my_agent.run('Testing my agent...')
        assert result.output == 'success (no tool calls)'
    assert m.last_model_request_parameters.function_tools == []
```

--------------------------------

### Agent Override with TestModel - Pydantic AI

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/testing.md

Demonstrates using Agent.override context manager to replace the agent's model with TestModel for safe testing. Allows customization of mock responses and prevents real LLM requests during unit tests.

```python
with agent.override(model=TestModel(custom_output_text='Sunny')):
    # Call the function to test inside the override context
    result = await agent.run(user_prompt)
```

--------------------------------

### Define a Dataset for Agent Evaluation with Pydantic Evals

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/agent.md

This example illustrates how to define a `Dataset` with test `Case`s for systematically evaluating agent behavior. It sets up an input and an expected output for a specific test scenario.

```python
from pydantic_evals import Case, Dataset

dataset = Dataset(
    name='agent_eval',
    cases=[
        Case(name='capital_question', inputs='What is the capital of France?', expected_output='Paris'),
    ]
)
report = dataset.evaluate_sync(my_agent_function)
```

--------------------------------

### Unit Testing Weather Forecast Tool with FunctionModel

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/testing.md

Demonstrates using FunctionModel to replace the LLM with a custom function that controls tool calls and responses. The function intercepts ModelMessages, extracts parameters from prompts using regex, and returns controlled ToolCallPart responses. This allows full exercise of tool logic without relying on actual LLM calls.

```python
import re

import pytest

from pydantic_ai import models
from pydantic_ai import (
    ModelMessage,
    ModelResponse,
    TextPart,
    ToolCallPart,
)
from pydantic_ai.models.function import AgentInfo, FunctionModel

from fake_database import DatabaseConn
from weather_app import run_weather_forecast, weather_agent

pytestmark = pytest.mark.anyio
models.ALLOW_MODEL_REQUESTS = False


def call_weather_forecast(
    messages: list[ModelMessage], info: AgentInfo
) -> ModelResponse:
    if len(messages) == 1:
        user_prompt = messages[0].parts[-1]
        m = re.search(r'\d{4}-\d{2}-\d{2}', user_prompt.content)
        assert m is not None
        args = {'location': 'London', 'forecast_date': m.group()}
        return ModelResponse(parts=[ToolCallPart('weather_forecast', args)])
    else:
        msg = messages[-1].parts[0]
        assert msg.part_kind == 'tool-return'
        return ModelResponse(parts=[TextPart(f'The forecast is: {msg.content}')])


async def test_forecast_future():
    conn = DatabaseConn()
    user_id = 1
    with weather_agent.override(model=FunctionModel(call_weather_forecast)):
        prompt = 'What will the weather be like in London on 2032-01-01?'
        await run_weather_forecast([(prompt, user_id)], conn)

    forecast = await conn.get_forecast(user_id)
    assert forecast == 'The forecast is: Rainy with a chance of sun'
```
