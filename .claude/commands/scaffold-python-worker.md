---
description: Scaffold a standalone Python 3.14 background worker service. Use for event-driven or scheduled processing jobs that are NOT FastAPI REST APIs and NOT AI agents.
argument-hint: "[service name]"
allowed-tools: Bash, Read, Write, Edit
---

# Scaffold: Python Background Worker

**Project name:** $ARGUMENTS

Use for services triggered by Pub/Sub, Cloud Scheduler, or GCS events — not for HTTP REST APIs or AI agents.

## Stack
- Python 3.14 + uv workspaces
- Shared service library editable install via `[tool.uv.sources]`
- structlog for logging
- pytest for tests

## Steps

1. **Read existing files** in the target directory before adding anything
2. **Initialize with uv:** `uv init $ARGUMENTS --python 3.14` under the appropriate `services/` subdirectory
3. **Add `[tool.uv.sources]`** with the shared service library as an editable install in `pyproject.toml`
4. **Create directory structure:**
   - `src/config.py` — pydantic-settings config, env vars (required fields have NO defaults)
   - `src/job.py` — `async def run_job(payload: dict) -> JobResult:` entry point
   - `src/processors/` — domain-specific processing modules
   - `src/main.py` — Pub/Sub or Cloud Scheduler handler (parses trigger payload, calls run_job)
   - `tests/test_job.py` — unit tests with mocked external clients
5. **Output:** write results to the database via the shared session factory — never connect directly
6. **Status reporting:** write job status to the canonical status store on completion/failure

## Critical Constraints
- Never bypass the shared database session factory — use the shared library's `get_session` / `AsyncSession` pattern
- Never use inline AI framework patterns (LangChain, LangGraph, etc.) in a worker service
- All failures must be logged via structlog and surfaced as records — never swallowed silently
- External API clients must be injected (not instantiated inline) to enable test mocking
- Required env vars must have NO defaults in config — missing values must raise `ValidationError` at startup

## Post-Scaffold
- Add the new service to `pyproject.toml` workspace members at repo root
- Verify `uv sync` at repo root resolves without error
- Add deployment configuration for Cloud Run or equivalent compute target
- Dispatch `python-worker-reviewer` after implementation is complete
