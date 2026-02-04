---
description: Scaffold a new Agentic AI service with Python 3.13, LangChain v1.2.x, LangGraph v1.0.x, FastAPI 0.128.x, and production infrastructure
allowed-tools: Bash, Read, Write, Edit
disable-model-invocation: true
---

# Scaffold Agentic AI Service

Create a production-ready agentic AI service with LangGraph, FastAPI, and full infrastructure.

## Project Name

Use `$ARGUMENTS` as the project name. If not provided, default to `my-agent-service`.

## Steps

1. **Initialize project** with `uv init $ARGUMENTS --python 3.13` in the current directory.

2. **Add production dependencies** with a single `uv add` command:
   `"langchain-core>=1.2.0" "langchain-anthropic>=1.3.0" "langchain-openai>=1.1.0" "langgraph>=1.0.0" "langgraph-checkpoint-postgres>=3.0.0" "fastapi>=0.128.0" "uvicorn[standard]" gunicorn pydantic pydantic-settings langsmith prometheus-client structlog httpx asyncpg`

3. **Add dev dependencies** with `uv add --dev`:
   `pytest pytest-asyncio httpx ruff mypy`

4. **Create directory structure** under `src/<service_name>/` (convert project name to snake_case):
   - `agents/graphs/`
   - `agents/nodes/`
   - `agents/tools/`
   - `rag/chains/`
   - `rag/indexing/`
   - `rag/retrieval/`
   - `memory/`
   - `guardrails/`
   - `llm/`
   - `core/`
   - `observability/`
   - `models/`
   - `api/routes/`
   - `api/middleware/`
   - `tests/`

5. **Write `core/config.py`** — Use the pattern from `agentic-ai-dev` skill reference `agentic-config-project.md`. Include pydantic-settings with fail-fast validators for `ANTHROPIC_API_KEY`, `DATABASE_URL`, and `CHECKPOINT_DB_URI`.

6. **Write `core/logging.py`** — structlog with JSON output (production) or ConsoleRenderer (development). Include correlation ID support via `contextvars`.

7. **Write `core/exceptions.py`** — Exception hierarchy: `AgentServiceError` → `AgentError`, `ToolError`, `LLMProviderError`, `GuardrailError`, `RAGError`.

8. **Write `agents/state.py`** — Base `AgentState` TypedDict with `messages: Annotated[list[BaseMessage], add_messages]`, `iteration_count: int`, `error_count: int`, `thread_id: str`.

9. **Write `agents/tools/search.py`** — Sample `@tool` function `search_web(query: str) -> str` with docstring, try/except, logging.

10. **Write `agents/nodes/agent_node.py`** — ReAct agent node function with error handling and iteration counting.

11. **Write `agents/graphs/react_agent.py`** — Full `build_react_agent()` function with `StateGraph`, `ToolNode`, conditional edges, iteration limit check, and checkpointer.

12. **Write `llm/providers.py`** — `LLMProviderFactory` class with `get_default()`, `get(provider, tier)`, `get_fallback_chain()`. Support Anthropic and OpenAI.

13. **Write `main.py`** — FastAPI app with `lifespan` context manager that initializes logging, LLM providers, and checkpointer. Include middleware and route registration.

14. **Write `api/routes/agent.py`** — `POST /api/v1/agent/invoke` and `POST /api/v1/agent/stream` endpoints. Use `Depends()` for graph injection. Include proper error handling.

15. **Write `api/routes/health.py`** — `GET /api/v1/health` with LLM provider ping and checkpointer status.

16. **Write `api/middleware/request_context.py`** — `RequestContextMiddleware` that injects correlation ID via `contextvars` and `structlog.contextvars`.

17. **Write `models/schemas.py`** — `AgentRequest` and `AgentResponse` Pydantic models.

18. **Write `tests/conftest.py`** — Fixtures for `mock_llm`, `mock_provider_factory`, `memory_checkpointer`, `thread_id`.

19. **Write `tests/test_agent.py`** — Basic tests: agent responds, iteration count increments, max iterations respected.

20. **Configure ruff + mypy** in `pyproject.toml`:
    - ruff: `target-version = "py313"`, select = `["E", "W", "F", "I", "B", "C4", "UP", "SIM", "RUF"]`
    - mypy: `strict = true`, ignore langchain imports

21. **Write `Dockerfile`** — Multi-stage: builder (uv sync) → runtime (gunicorn + uvicorn workers). Non-root user, health check.

22. **Write `docker-compose.dev.yml`** — app + postgres (pgvector) + redis. Health checks on all services.

23. **Write `.env`** using Bash `cat > .env << 'EOF'` with placeholder values for all required environment variables.

24. **Add `__init__.py`** files to all packages.

25. **Add `py.typed`** marker file for PEP 561.

26. **Verify** by running:
    - `ruff check src/` — should pass with no errors
    - `mypy src/` — should pass (may have langchain import warnings)
    - Print a summary of what was created

## Reference

All code patterns should follow the `agentic-ai-dev` skill reference files. Consult them for exact code templates.
