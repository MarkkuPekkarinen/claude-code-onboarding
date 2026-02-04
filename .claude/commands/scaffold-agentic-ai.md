---
description: Scaffold a new Agentic AI service with Python 3.13, LangChain v1.2.8, LangGraph v1.0.7, FastAPI 0.128.x, and production infrastructure
argument-hint: "[project name]"
allowed-tools: Bash, Read, Write, Edit
disable-model-invocation: true
---

# Scaffold Agentic AI Service

Create a production-ready agentic AI service with LangGraph, FastAPI, and full infrastructure.

**Project name:** $ARGUMENTS (default to "my-agent-service" if not provided)

## Steps

1. **Initialize project** — `uv init $ARGUMENTS --python 3.13` in the current directory.
2. **Add production dependencies** — `uv add "langchain-core>=1.2.8" "langchain-anthropic>=1.3.0" "langchain-openai>=1.1.0" "langgraph>=1.0.7" "langgraph-checkpoint-postgres>=3.0.0" "fastapi>=0.128.0" "uvicorn[standard]" gunicorn pydantic pydantic-settings langsmith prometheus-client structlog httpx asyncpg`
3. **Add dev dependencies** — `uv add --dev pytest pytest-asyncio httpx ruff mypy`
4. **Create directory structure** under `src/<service_name>/` (snake_case): `agents/graphs/`, `agents/nodes/`, `agents/tools/`, `rag/chains/`, `rag/indexing/`, `rag/retrieval/`, `memory/`, `guardrails/`, `llm/`, `core/`, `observability/`, `models/`, `api/routes/`, `api/middleware/`, `tests/`
5. **Create core modules** — `core/config.py` (pydantic-settings, fail-fast), `core/logging.py` (structlog), `core/exceptions.py` (exception hierarchy). Follow `agentic-ai-dev` skill reference `agentic-config-project.md` for patterns.
6. **Create agent layer** — `agents/state.py` (AgentState TypedDict), `agents/tools/search.py` (sample tool), `agents/nodes/agent_node.py` (ReAct node), `agents/graphs/react_agent.py` (StateGraph with ToolNode, conditional edges, checkpointer). Read skill reference files for exact templates.
7. **Create LLM providers** — `llm/providers.py` with factory supporting Anthropic and OpenAI, fallback chain.
8. **Create API layer** — `main.py` (FastAPI with lifespan), `api/routes/agent.py` (invoke + stream endpoints), `api/routes/health.py`, `api/middleware/request_context.py` (correlation ID), `models/schemas.py` (Pydantic models).
9. **Create tests** — `tests/conftest.py` (fixtures) and `tests/test_agent.py` (basic agent tests).
10. **Configure tooling** — ruff (`target-version = "py313"`) and mypy (`strict = true`) in `pyproject.toml`.
11. **Create infrastructure** — `Dockerfile` (multi-stage, non-root), `docker-compose.dev.yml` (app + postgres/pgvector + redis), `.env` via Bash with placeholder values.
12. **Add package files** — `__init__.py` in all packages, `py.typed` marker for PEP 561.
13. **Verify** — Run `ruff check src/` and `mypy src/`. Print a summary of created files and next steps.

## Reference

All code patterns should follow the `agentic-ai-dev` skill reference files. Consult them for exact code templates.
