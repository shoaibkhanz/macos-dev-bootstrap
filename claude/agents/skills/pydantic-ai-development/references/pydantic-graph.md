### Define Graph Nodes and State Transitions in Python

Source: https://github.com/pydantic/pydantic-ai/blob/main/pydantic_graph/README.md

Create a graph-based state machine using BaseNode subclasses with async run methods. Nodes define transitions through return type hints, supporting conditional logic to route between different node states or terminal End states. This example demonstrates a graph that increments a value until it's divisible by 5.

```python
from __future__ import annotations

from dataclasses import dataclass

from pydantic_graph import BaseNode, End, Graph, GraphRunContext


@dataclass
class DivisibleBy5(BaseNode[None, None, int]):
    foo: int

    async def run(
        self,
        ctx: GraphRunContext,
    ) -> Increment | End[int]:
        if self.foo % 5 == 0:
            return End(self.foo)
        else:
            return Increment(self.foo)


@dataclass
class Increment(BaseNode):
    foo: int

    async def run(self, ctx: GraphRunContext) -> DivisibleBy5:
        return DivisibleBy5(self.foo + 1)


fives_graph = Graph(nodes=[DivisibleBy5, Increment])
result = fives_graph.run_sync(DivisibleBy5(4))
print(result.output)
#> 5
```

--------------------------------

### Build State-Machine Workflows with Pydantic Graph

Source: https://context7.com/pydantic/pydantic-ai/llms.txt

Create complex workflows using nodes and edges defined by type hints. This example shows a cyclic graph that increments a value until a specific condition is met, and demonstrates how to generate Mermaid diagrams for visualization.

```python
from __future__ import annotations
from dataclasses import dataclass
from pydantic_graph import BaseNode, End, Graph, GraphRunContext

@dataclass
class DivisibleBy5(BaseNode[None, None, int]):
    foo: int

    async def run(self, ctx: GraphRunContext) -> Increment | End[int]:
        if self.foo % 5 == 0:
            return End(self.foo)
        return Increment(self.foo)

@dataclass
class Increment(BaseNode):
    foo: int

    async def run(self, ctx: GraphRunContext) -> DivisibleBy5:
        return DivisibleBy5(self.foo + 1)

# Create and run the graph
graph = Graph(nodes=[DivisibleBy5, Increment])
result = graph.run_sync(DivisibleBy5(4))
print(result.output)  # Output: 5

# Generate mermaid diagram
print(graph.mermaid_code(start_node=DivisibleBy5))
```

--------------------------------

### Define and Run an Execution Graph with Pydantic Graph

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/graph.md

This example demonstrates how to define nodes using dataclasses and BaseNode, implement logic within the run method, and execute the graph synchronously using run_sync.

```python
from __future__ import annotations

from dataclasses import dataclass

from pydantic_graph import BaseNode, End, Graph, GraphRunContext


@dataclass
class DivisibleBy5(BaseNode[None, None, int]):  # (1)!
    foo: int

    async def run(
        self,
        ctx: GraphRunContext,
    ) -> Increment | End[int]:
        if self.foo % 5 == 0:
            return End(self.foo)
        else:
            return Increment(self.foo)


@dataclass
class Increment(BaseNode):  # (2)!
    foo: int

    async def run(self, ctx: GraphRunContext) -> DivisibleBy5:
        return DivisibleBy5(self.foo + 1)


fives_graph = Graph(nodes=[DivisibleBy5, Increment])  # (3)!
result = fives_graph.run_sync(DivisibleBy5(4))  # (4)!
print(result.output)
#> 5
```

--------------------------------

### Run Human-in-the-Loop AI Graph with Persistence

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/graph.md

This Python script demonstrates how to run the `question_graph` defined previously, incorporating 'human in the loop' functionality. It uses `FileStatePersistence` to save and load the graph's state, allowing the process to be interrupted for user input and resumed. The script checks for a command-line argument to provide an answer, simulating user interaction and enabling the graph to continue from its last saved state.

```python
import sys
from pathlib import Path

from pydantic_graph import End
from pydantic_graph.persistence.file import FileStatePersistence
from pydantic_ai import ModelMessage  # noqa: F401

from ai_q_and_a_graph import Ask, question_graph, Evaluate, QuestionState, Answer


async def main():
    answer: str | None = sys.argv[1] if len(sys.argv) > 1 else None  # (1)!
    persistence = FileStatePersistence(Path('question_graph.json'))  # (2)!
    persistence.set_graph_types(question_graph)  # (3)!

    if snapshot := await persistence.load_next():  # (4)!
        state = snapshot.state
        assert answer is not None
        node = Evaluate(answer)
    else:
        state = QuestionState()
        node = Ask()  # (5)!

    async with question_graph.iter(node, state=state, persistence=persistence) as run:
        while True:
            node = await run.next()  # (6)!
            if isinstance(node, End):  # (7)!
```

--------------------------------

### Define a pydantic-graph node that can optionally end the run

Source: https://github.com/pydantic/pydantic-ai/blob/main/docs/graph.md

This example extends a pydantic-graph node to conditionally terminate the graph execution. The 'run' method returns either another node for continuation or an 'End' object with a result, based on a condition. This requires parameterizing BaseNode with the graph's return type (e.g., 'int' for the 'End' result) and including 'None' for unused generic parameters.

```python
from dataclasses import dataclass

from pydantic_graph import BaseNode, End, GraphRunContext


@dataclass
class MyNode(BaseNode[MyState, None, int]):  # (1)!
    foo: int

    async def run(
        self,
        ctx: GraphRunContext[MyState],
    ) -> AnotherNode | End[int]:  # (2)!
        if self.foo % 5 == 0:
            return End(self.foo)
        else:
            return AnotherNode()
```
