### Create FastMCP Server with Pydantic AI Agent

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/mcp/server.md

Sets up a basic MCP server using FastMCP that exposes a Pydantic AI agent as a tool. The server creates an agent configured with Claude Haiku and a rhyming instruction, then wraps it in a server tool that generates poems based on user input.

```python
from mcp.server.fastmcp import FastMCP

from pydantic_ai import Agent

server = FastMCP('Pydantic AI Server')
server_agent = Agent(
    'anthropic:claude-haiku-4-5', instructions='always reply in rhyme'
)


@server.tool()
async def poet(theme: str) -> str:
    """Poem generator"""
    r = await server_agent.run(f'write a poem about {theme}')
    return r.output


if __name__ == '__main__':
    server.run()
```

--------------------------------

### Connect Pydantic AI Agent to a Streamable HTTP MCP Server in Python

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/mcp/fastmcp-client.md

This Python snippet demonstrates how to connect a Pydantic AI agent to a remote Streamable HTTP MCP server. By simply providing the server's URL to the `FastMCPToolset`, the agent can interact with the tools exposed by that server.

```python
from pydantic_ai import Agent
from pydantic_ai.toolsets.fastmcp import FastMCPToolset

toolset = FastMCPToolset('http://localhost:8000/mcp')

agent = Agent('openai:gpt-5.2', toolsets=[toolset])
```

--------------------------------

### Connect Pydantic AI Agent to a local FastMCP Server in Python

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/mcp/fastmcp-client.md

This Python example illustrates how to integrate a Pydantic AI agent with a locally defined FastMCP server. It shows the process of creating a FastMCP server, defining a tool on it, wrapping the server with `FastMCPToolset`, and then configuring an agent to use this toolset for task execution.

```python
from fastmcp import FastMCP

from pydantic_ai import Agent
from pydantic_ai.toolsets.fastmcp import FastMCPToolset

fastmcp_server = FastMCP('my_server')
@fastmcp_server.tool()
async def add(a: int, b: int) -> int:
    return a + b

toolset = FastMCPToolset(fastmcp_server)

agent = Agent('openai:gpt-5.2', toolsets=[toolset])

async def main():
    result = await agent.run('What is 7 plus 5?')
    print(result.output)
    # The answer is 12.
```

--------------------------------

### Connect Pydantic AI Agent using a JSON MCP Configuration in Python

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/mcp/fastmcp-client.md

This example shows how to initialize the `FastMCPToolset` using a dictionary that represents a JSON MCP configuration. This method allows an agent to connect to multiple MCP servers defined within a single configuration object, providing a flexible way to manage server connections.

```python
from pydantic_ai import Agent
from pydantic_ai.toolsets.fastmcp import FastMCPToolset

mcp_config = {
    'mcpServers': {
        'time_mcp_server': {
            'command': 'uvx',
            'args': ['mcp-run-python', 'stdio']
        },
        'weather_server': {
            'command': 'python',
            'args': ['mcp_server.py']
        }
    }
}

toolset = FastMCPToolset(mcp_config)

agent = Agent('openai:gpt-5.2', toolsets=[toolset])
```

--------------------------------

### Initialize FastMCPToolset with various FastMCP components or configurations in Python

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/mcp/fastmcp-client.md

These examples demonstrate different ways to instantiate the `FastMCPToolset` in Python. It can be initialized directly from a FastMCP Server, Client, Transport, a streamable HTTP URL, an HTTP SSE URL, a Python script, a Node.js script, or a JSON MCP configuration, providing flexibility in connecting to various MCP server types.

```python
FastMCPToolset(fastmcp.FastMCP('my_server'))
```

```python
FastMCPToolset(fastmcp.Client(...))
```

```python
FastMCPToolset(fastmcp.StdioTransport(command='python', args=['mcp_server.py']))
```

```python
FastMCPToolset('http://localhost:8000/mcp')
```

```python
FastMCPToolset('http://localhost:8000/sse')
```

```python
FastMCPToolset('my_server.py')
```

```python
FastMCPToolset('my_server.js')
```

```python
FastMCPToolset({'mcpServers': {'my_server': {'command': 'python', 'args': ['mcp_server.py']}}})
```
