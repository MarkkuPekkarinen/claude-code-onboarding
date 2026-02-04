# Agentic AI Agent Graph Patterns

Six production-ready LangGraph agent patterns. Each pattern includes typed state, proper error handling, iteration limits, and checkpointing.

## Pattern 1: ReAct Agent

The foundational agent pattern — reason and act in a loop with tool use.

**File:** `src/<service>/agents/graphs/react_agent.py`

```python
from __future__ import annotations

from typing import Literal

from langchain_core.messages import AIMessage
from langgraph.graph import END, StateGraph
from langgraph.prebuilt import ToolNode

from ...core.logging import get_logger
from ...llm.providers import LLMProviderFactory
from ..state import AgentState
from ..tools.search import search_tool, calculator_tool

logger = get_logger(__name__)

MAX_ITERATIONS = 25


def build_react_agent(
    provider_factory: LLMProviderFactory,
    checkpointer=None,
) -> StateGraph:
    """Build a ReAct agent graph with tool use.

    Args:
        provider_factory: Factory for LLM provider instances.
        checkpointer: LangGraph checkpointer for state persistence.

    Returns:
        Compiled StateGraph ready for invocation.
    """
    tools = [search_tool, calculator_tool]
    llm = provider_factory.get_default().bind_tools(tools)

    # --- Nodes ---

    async def agent_node(state: AgentState) -> dict:
        """Core reasoning node — invoke LLM with current state."""
        logger.info("agent_reasoning", iteration=state["iteration_count"])
        response = await llm.ainvoke(state["messages"])
        return {
            "messages": [response],
            "iteration_count": state["iteration_count"] + 1,
        }

    # --- Routing ---

    def should_continue(state: AgentState) -> Literal["tools", "__end__"]:
        """Route based on whether the LLM wants to use tools or is done."""
        if state["iteration_count"] >= MAX_ITERATIONS:
            logger.warning("max_iterations_reached", count=state["iteration_count"])
            return END

        last_message = state["messages"][-1]
        if isinstance(last_message, AIMessage) and last_message.tool_calls:
            return "tools"
        return END

    # --- Graph Assembly ---

    graph = StateGraph(AgentState)
    graph.add_node("agent", agent_node)
    graph.add_node("tools", ToolNode(tools))

    graph.set_entry_point("agent")
    graph.add_conditional_edges("agent", should_continue)
    graph.add_edge("tools", "agent")

    return graph.compile(checkpointer=checkpointer)
```

## Pattern 2: Multi-Agent Collaborative

Multiple specialist agents collaborate on complex tasks with shared state.

**File:** `src/<service>/agents/graphs/multi_agent.py`

```python
from __future__ import annotations

from typing import Literal

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage
from langgraph.graph import END, StateGraph

from ...core.logging import get_logger
from ...llm.providers import LLMProviderFactory
from ..state import MultiAgentState

logger = get_logger(__name__)


def build_multi_agent(
    provider_factory: LLMProviderFactory,
    checkpointer=None,
) -> StateGraph:
    """Build a multi-agent collaborative graph.

    Architecture:
        router → [researcher | analyst | writer] → synthesizer → END

    Each specialist processes the task independently, then the synthesizer
    combines their outputs into a final response.
    """
    llm = provider_factory.get_default()

    # --- Specialist Nodes ---

    async def router_node(state: MultiAgentState) -> dict:
        """Analyze the task and create a plan for specialists."""
        response = await llm.ainvoke([
            SystemMessage(content="You are a task router. Analyze the request and create a plan. "
                          "Decide which specialists are needed: researcher, analyst, writer."),
            *state["messages"],
        ])
        # Parse the plan from the response
        plan = ["researcher", "analyst", "writer"]  # Simplified; parse from LLM response
        return {
            "messages": [response],
            "task_plan": plan,
            "current_agent": "researcher",
            "iteration_count": state["iteration_count"] + 1,
        }

    async def researcher_node(state: MultiAgentState) -> dict:
        """Research specialist — gathers information and facts."""
        response = await llm.ainvoke([
            SystemMessage(content="You are a research specialist. Gather relevant facts and information."),
            *state["messages"],
        ])
        outputs = {**state.get("agent_outputs", {}), "researcher": response.content}
        completed = [*state.get("completed_tasks", []), "researcher"]
        return {
            "messages": [response],
            "agent_outputs": outputs,
            "completed_tasks": completed,
            "iteration_count": state["iteration_count"] + 1,
        }

    async def analyst_node(state: MultiAgentState) -> dict:
        """Analysis specialist — identifies patterns and insights."""
        context = state.get("agent_outputs", {}).get("researcher", "")
        response = await llm.ainvoke([
            SystemMessage(content=f"You are an analysis specialist. Research context:\n{context}"),
            *state["messages"],
        ])
        outputs = {**state.get("agent_outputs", {}), "analyst": response.content}
        completed = [*state.get("completed_tasks", []), "analyst"]
        return {
            "messages": [response],
            "agent_outputs": outputs,
            "completed_tasks": completed,
            "iteration_count": state["iteration_count"] + 1,
        }

    async def writer_node(state: MultiAgentState) -> dict:
        """Writing specialist — produces the final written output."""
        research = state.get("agent_outputs", {}).get("researcher", "")
        analysis = state.get("agent_outputs", {}).get("analyst", "")
        response = await llm.ainvoke([
            SystemMessage(content=f"You are a writing specialist.\nResearch:\n{research}\nAnalysis:\n{analysis}"),
            *state["messages"],
        ])
        outputs = {**state.get("agent_outputs", {}), "writer": response.content}
        completed = [*state.get("completed_tasks", []), "writer"]
        return {
            "messages": [response],
            "agent_outputs": outputs,
            "completed_tasks": completed,
            "iteration_count": state["iteration_count"] + 1,
        }

    async def synthesizer_node(state: MultiAgentState) -> dict:
        """Combine all specialist outputs into a coherent final response."""
        all_outputs = "\n\n".join(
            f"=== {agent} ===\n{output}"
            for agent, output in state.get("agent_outputs", {}).items()
        )
        response = await llm.ainvoke([
            SystemMessage(content=f"Synthesize these specialist outputs into one coherent response:\n{all_outputs}"),
            HumanMessage(content=state["messages"][0].content),
        ])
        return {
            "messages": [response],
            "iteration_count": state["iteration_count"] + 1,
        }

    # --- Routing ---

    def route_next_specialist(state: MultiAgentState) -> str:
        """Route to the next incomplete specialist or to synthesizer."""
        plan = state.get("task_plan", [])
        completed = state.get("completed_tasks", [])
        for task in plan:
            if task not in completed:
                return task
        return "synthesizer"

    # --- Graph Assembly ---

    graph = StateGraph(MultiAgentState)
    graph.add_node("router", router_node)
    graph.add_node("researcher", researcher_node)
    graph.add_node("analyst", analyst_node)
    graph.add_node("writer", writer_node)
    graph.add_node("synthesizer", synthesizer_node)

    graph.set_entry_point("router")
    graph.add_conditional_edges("router", route_next_specialist)
    graph.add_conditional_edges("researcher", route_next_specialist)
    graph.add_conditional_edges("analyst", route_next_specialist)
    graph.add_conditional_edges("writer", route_next_specialist)
    graph.add_edge("synthesizer", END)

    return graph.compile(checkpointer=checkpointer)
```

## Pattern 3: Hierarchical Supervisor

A supervisor delegates to specialists and controls quality.

**File:** `src/<service>/agents/graphs/supervisor_agent.py`

```python
from __future__ import annotations

from typing import Literal

from langchain_core.messages import AIMessage, SystemMessage
from langgraph.graph import END, StateGraph
from langgraph.types import Command

from ...core.logging import get_logger
from ...llm.providers import LLMProviderFactory
from ..state import MultiAgentState

logger = get_logger(__name__)

SUPERVISOR_PROMPT = """You are a supervisor managing a team of specialists.
Available specialists: {specialists}

For each user request:
1. Decide which specialist should handle it
2. Review the specialist's output
3. Either approve (respond to user) or request revision

Respond with JSON: {{"route": "specialist_name"}} or {{"route": "FINISH", "response": "final answer"}}
"""


def build_supervisor_agent(
    provider_factory: LLMProviderFactory,
    checkpointer=None,
) -> StateGraph:
    """Build a hierarchical supervisor agent.

    The supervisor decides which specialist to invoke, reviews output,
    and iterates until quality is sufficient.
    """
    llm = provider_factory.get_default()
    specialists = ["researcher", "coder", "reviewer"]

    async def supervisor_node(state: MultiAgentState) -> Command:
        """Supervisor decides next action based on current state."""
        response = await llm.with_structured_output(SupervisorDecision).ainvoke([
            SystemMessage(content=SUPERVISOR_PROMPT.format(specialists=specialists)),
            *state["messages"],
        ])

        if response.route == "FINISH":
            return Command(
                goto=END,
                update={
                    "messages": [AIMessage(content=response.response)],
                    "iteration_count": state["iteration_count"] + 1,
                },
            )

        return Command(
            goto=response.route,
            update={"iteration_count": state["iteration_count"] + 1},
        )

    async def researcher_node(state: MultiAgentState) -> Command:
        """Research specialist — returns to supervisor for review."""
        response = await llm.ainvoke([
            SystemMessage(content="You are a research specialist. Provide thorough, factual research."),
            *state["messages"],
        ])
        return Command(
            goto="supervisor",
            update={"messages": [response]},
        )

    async def coder_node(state: MultiAgentState) -> Command:
        """Coding specialist — returns to supervisor for review."""
        response = await llm.ainvoke([
            SystemMessage(content="You are a coding specialist. Write clean, tested, production code."),
            *state["messages"],
        ])
        return Command(
            goto="supervisor",
            update={"messages": [response]},
        )

    async def reviewer_node(state: MultiAgentState) -> Command:
        """Review specialist — returns to supervisor with feedback."""
        response = await llm.ainvoke([
            SystemMessage(content="You are a code reviewer. Review for correctness, security, and style."),
            *state["messages"],
        ])
        return Command(
            goto="supervisor",
            update={"messages": [response]},
        )

    # --- Graph Assembly ---

    graph = StateGraph(MultiAgentState)
    graph.add_node("supervisor", supervisor_node)
    graph.add_node("researcher", researcher_node)
    graph.add_node("coder", coder_node)
    graph.add_node("reviewer", reviewer_node)

    graph.set_entry_point("supervisor")
    # Edges are handled by Command returns — no explicit conditional edges needed

    return graph.compile(checkpointer=checkpointer)


# Pydantic model for structured supervisor output
from pydantic import BaseModel, Field


class SupervisorDecision(BaseModel):
    """Structured output for supervisor routing decisions."""

    route: Literal["researcher", "coder", "reviewer", "FINISH"]
    response: str = Field(default="", description="Final response when route is FINISH")
```

## Pattern 4: LangGraph Command Pattern

The preferred routing pattern in LangGraph — cleaner than conditional edges for complex flows.

```python
from langgraph.types import Command

# Instead of conditional edges, nodes return Command objects

async def triage_node(state: AgentState) -> Command:
    """Route using Command pattern — cleaner than conditional edges."""
    analysis = await llm.ainvoke([
        SystemMessage(content="Classify this request: technical, billing, or general"),
        *state["messages"],
    ])

    category = parse_category(analysis.content)

    return Command(
        goto=category,  # Route to the appropriate node
        update={
            "messages": [analysis],
            "iteration_count": state["iteration_count"] + 1,
        },
    )

# Graph setup — no conditional edges needed
graph = StateGraph(AgentState)
graph.add_node("triage", triage_node)
graph.add_node("technical", technical_node)
graph.add_node("billing", billing_node)
graph.add_node("general", general_node)
graph.set_entry_point("triage")
# Command handles all routing — just add edges back to triage if needed
graph.add_edge("technical", END)
graph.add_edge("billing", END)
graph.add_edge("general", END)
```

## Pattern 5: Sub-Graph Composition

Reusable sub-graphs composed into a larger workflow.

```python
from langgraph.graph import StateGraph, END


def build_rag_subgraph(provider_factory) -> StateGraph:
    """Reusable RAG sub-graph that can be embedded in any parent graph."""
    graph = StateGraph(RAGState)
    graph.add_node("retrieve", retrieve_node)
    graph.add_node("grade", grade_documents_node)
    graph.add_node("generate", generate_node)

    graph.set_entry_point("retrieve")
    graph.add_edge("retrieve", "grade")
    graph.add_conditional_edges("grade", grade_router)
    graph.add_edge("generate", END)

    return graph.compile()


def build_parent_agent(provider_factory, checkpointer=None) -> StateGraph:
    """Parent graph that uses RAG as a sub-graph."""
    rag_graph = build_rag_subgraph(provider_factory)

    async def rag_node(state: AgentState) -> dict:
        """Delegate to RAG sub-graph."""
        result = await rag_graph.ainvoke({
            "messages": state["messages"],
            "query": state["messages"][-1].content,
            "documents": [],
            "generation": "",
            "is_grounded": False,
            "iteration_count": 0,
            "error_count": 0,
            "thread_id": state["thread_id"],
        })
        return {"messages": result["messages"]}

    graph = StateGraph(AgentState)
    graph.add_node("agent", agent_node)
    graph.add_node("rag", rag_node)
    graph.add_node("tools", tool_node)

    graph.set_entry_point("agent")
    graph.add_conditional_edges("agent", route_agent)
    graph.add_edge("rag", "agent")
    graph.add_edge("tools", "agent")

    return graph.compile(checkpointer=checkpointer)
```

## Pattern 6: Error Recovery Agent

Built-in retry, fallback, and graceful degradation.

```python
from __future__ import annotations

from langchain_core.messages import AIMessage
from langgraph.graph import END, StateGraph

from ...core.exceptions import LLMProviderError
from ...core.logging import get_logger

logger = get_logger(__name__)

MAX_ERRORS = 3


def build_resilient_agent(provider_factory, checkpointer=None) -> StateGraph:
    """Agent with built-in error recovery and fallback."""

    primary_llm = provider_factory.get("anthropic")
    fallback_llm = provider_factory.get("openai")

    async def agent_node(state: AgentState) -> dict:
        """Try primary LLM, fall back to secondary on failure."""
        error_count = state.get("error_count", 0)

        try:
            # Use fallback after repeated errors
            llm = fallback_llm if error_count >= 2 else primary_llm
            response = await llm.ainvoke(state["messages"])
            return {
                "messages": [response],
                "iteration_count": state["iteration_count"] + 1,
                "error_count": 0,  # Reset on success
            }

        except LLMProviderError as e:
            logger.warning("llm_error", error=str(e), error_count=error_count + 1)
            return {
                "messages": [AIMessage(content=f"Retrying after error: {e}")],
                "error_count": error_count + 1,
                "iteration_count": state["iteration_count"] + 1,
            }

    def should_continue(state: AgentState) -> str:
        """Check error budget and iteration limit."""
        if state.get("error_count", 0) >= MAX_ERRORS:
            logger.error("error_budget_exhausted")
            return "fallback"
        if state["iteration_count"] >= 25:
            return END
        last = state["messages"][-1]
        if isinstance(last, AIMessage) and last.tool_calls:
            return "tools"
        return END

    async def fallback_node(state: AgentState) -> dict:
        """Graceful degradation — return a helpful error message."""
        return {
            "messages": [AIMessage(
                content="I'm experiencing technical difficulties. "
                "Please try again in a moment or rephrase your request."
            )],
        }

    graph = StateGraph(AgentState)
    graph.add_node("agent", agent_node)
    graph.add_node("tools", ToolNode(tools))
    graph.add_node("fallback", fallback_node)

    graph.set_entry_point("agent")
    graph.add_conditional_edges("agent", should_continue)
    graph.add_edge("tools", "agent")
    graph.add_edge("fallback", END)

    return graph.compile(checkpointer=checkpointer)
```

## Key Design Decisions

| Decision | Recommendation | Reason |
|----------|---------------|--------|
| State typing | Always `TypedDict` | Type safety, IDE support, LangGraph compatibility |
| Routing | `Command` pattern | Cleaner than conditional edges, co-locates routing logic with node |
| Error handling | Error counter + fallback node | Prevents infinite retry loops, graceful degradation |
| Checkpointing | Always configure | Enables conversation memory, crash recovery, HITL |
| Iteration limit | Check in routing function | Hard safety boundary against infinite loops |
| LLM instantiation | Factory function | Centralizes config, enables fallback chains |
