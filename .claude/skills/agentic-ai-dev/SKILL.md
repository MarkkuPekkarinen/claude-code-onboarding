---
name: agentic-ai-dev
description: "This skill provides patterns and templates for building production AI agents with Python 3.13, LangChain v1.2.8, LangGraph v1.0.7, and FastAPI 0.128.x. Use when creating AI agents, RAG systems, graph workflows, tools, memory systems, or agent tests."
allowed-tools: Bash, Read, Write, Edit
---

# Agentic AI Development Skill — Python 3.13 + LangChain + LangGraph + FastAPI

## Quick Scaffold

```bash
uv init my-agent-service && cd my-agent-service
uv add "langchain-core>=1.2.8" "langchain-anthropic>=1.3.0" "langchain-openai>=1.1.0" "langgraph>=1.0.7" \
  "fastapi>=0.128.0" "uvicorn[standard]" pydantic pydantic-settings \
  langsmith prometheus-client structlog httpx asyncpg \
  "langgraph-checkpoint-postgres>=3.0.0"
uv add --dev pytest pytest-asyncio httpx ruff mypy
```

## Process

1. **Scaffold** — `uv init` + install dependencies
2. **Configure** — `core/config.py` with pydantic-settings, `.env`, structured logging
3. **Define State** — `TypedDict` with `Annotated[list, add_messages]` for each agent
4. **Build Graph** — `StateGraph` with typed nodes, conditional edges, checkpointing
5. **Define Tools** — `@tool` with docstrings, Pydantic input schemas, error handling
6. **Add Memory** — Checkpointing (PostgresSaver), semantic memory (vector store)
7. **Add Guardrails** — Input validation, prompt injection detection, output validation
8. **Expose API** — FastAPI routes for invoke/stream with `thread_id` propagation
9. **Write Tests** — Basic invoke, tool usage, iteration limit, error recovery, RAG quality
10. **Deploy** — Docker multi-stage, gunicorn + uvicorn, health checks, Prometheus

## Key Patterns

| Pattern | Implementation | Reference |
|---------|---------------|-----------|
| Agent Graphs | `StateGraph` + typed nodes + conditional edges | `agentic-templates-agents.md` |
| Tools | `@tool` + docstring + Pydantic input + try/except | `agentic-templates-tools.md` |
| LLM Binding | Factory function per provider, `.bind_tools()` | `agentic-llm-routing.md` |
| Routing | `Command(goto=...)` pattern (LangGraph) | `agentic-templates-agents.md` |
| Checkpointing | `PostgresSaver` (prod) / `MemorySaver` (test) | `agentic-memory-systems.md` |
| Streaming | `astream()` + `stream_mode` + FastAPI SSE | `agentic-streaming-hitl.md` |
| Human-in-the-Loop | `interrupt_before` + approval node | `agentic-streaming-hitl.md` |
| RAG | Embeddings → Vector Store → Retriever → Reranker | `agentic-templates-rag.md` |
| Guardrails | 12-layer pipeline: input → process → output | `agentic-guardrails-security.md` |
| Structured Output | `.with_structured_output(PydanticModel)` | `agentic-prompt-engineering.md` |
| Error Recovery | Retry node + fallback model + graceful degradation | `agentic-templates-agents.md` |
| Config | pydantic-settings + fail-fast validators | `agentic-config-project.md` |

## Package Layout

```
src/<service_name>/
├── agents/
│   ├── graphs/          # StateGraph definitions (build_*_agent functions)
│   ├── nodes/           # Node functions (verb_node pattern)
│   ├── tools/           # @tool definitions
│   └── state.py         # TypedDict state schemas
├── rag/
│   ├── chains/          # RAG chain compositions
│   ├── indexing/        # Document loaders, splitters, indexing
│   └── retrieval/       # Retrievers, rerankers
├── memory/
│   ├── checkpointing.py # PostgresSaver setup
│   └── semantic.py      # Vector store long-term memory
├── guardrails/
│   ├── input.py         # Input validation pipeline
│   └── output.py        # Output validation pipeline
├── llm/
│   └── providers.py     # LLM factory, multi-provider router
├── core/
│   ├── config.py        # pydantic-settings configuration
│   ├── logging.py       # structlog setup
│   └── exceptions.py    # Exception hierarchy
├── observability/
│   ├── metrics.py       # Prometheus metrics
│   └── tracing.py       # LangSmith tracing setup
├── models/
│   └── schemas.py       # Pydantic request/response models
├── api/
│   ├── routes/
│   │   ├── agent.py     # POST /invoke, POST /stream
│   │   └── health.py    # GET /health
│   └── middleware/
│       └── request_context.py  # Correlation ID via contextvars
├── main.py              # FastAPI app with lifespan
└── py.typed             # PEP 561 marker
```

## LangGraph Rules

1. **Always use `TypedDict` for state** — never `dict[str, Any]`
2. **Always use `Annotated[list[BaseMessage], add_messages]`** for message lists — enables proper message merging
3. **Always include `iteration_count: int`** in state — check in routing function to prevent infinite loops
4. **Prefer `Command(goto=...)` pattern** for routing between nodes — cleaner than conditional edges for complex flows
5. **Always set `recursion_limit`** in config (default: 25) — safety net for runaway graphs
6. **Use `PostgresSaver` in production** — `MemorySaver` is for tests only; it's not persistent
7. **Always pass `thread_id` in config** — `{"configurable": {"thread_id": "..."}}`; required for checkpointing

## FastAPI Integration Rules

1. **All endpoints are `async def`** — never block the event loop
2. **Use `Depends()` for agent graph injection** — configure in lifespan, inject via dependency
3. **Use `StreamingResponse` with `text/event-stream`** — for streaming agent responses
4. **Include `/api/v1/health`** — ping LLM providers, DB, vector store
5. **Propagate `thread_id`** from request to graph config — enables conversation continuity

## Reference Files

| File | Content | When to Use |
|------|---------|-------------|
| `agentic-config-project.md` | pyproject.toml, .env, config, Docker, ruff/mypy | Project setup |
| `agentic-templates-core.md` | FastAPI app, main.py, routes, middleware, base state | Creating API layer |
| `agentic-templates-agents.md` | 6 LangGraph agent patterns (ReAct, Multi-Agent, Supervisor, Command, Sub-Graph, Error Recovery) | Building any agent |
| `agentic-templates-rag.md` | 6 RAG architectures + document ingestion pipeline | Building RAG systems |
| `agentic-templates-tools.md` | @tool patterns, MCP integration, retry/timeout | Defining agent tools |
| `agentic-guardrails-security.md` | 12-layer security framework | Adding safety layers |
| `agentic-memory-systems.md` | 7-layer memory hierarchy, practical implementations | Adding memory to agents |
| `agentic-streaming-hitl.md` | Streaming + Human-in-the-Loop patterns | Real-time responses, approval flows |
| `agentic-llm-routing.md` | Multi-provider routing, cost calculation, fallback chains | Multi-model setups |
| `agentic-observability.md` | LangSmith, Prometheus, structured logging | Monitoring and debugging |
| `agentic-testing.md` | Agent testing patterns, mocks, fixtures | Writing agent tests |
| `agentic-deployment.md` | Docker, docker-compose, production config | Deploying agents |
| `agentic-debugging.md` | Debugging playbook, common issues | Troubleshooting agents |
| `agentic-cost-optimization.md` | Cost management, budget caps, prompt optimization | Reducing LLM costs |
| `agentic-prompt-engineering.md` | Advanced prompting, structured output, templates | Writing better prompts |
| `agentic-error-handling.md` | Agent, tool, LLM provider, and API error handling patterns | Error handling in agents |

> For error handling patterns and code examples, read reference/agentic-error-handling.md
