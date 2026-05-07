---
name: python-dev
description: This skill provides patterns and templates for Python 3.14 development with FastAPI and modern tooling. It should be activated when creating Python APIs, scripts, data processing pipelines, or pytest tests.
allowed-tools: Bash, Read, Write, Edit
metadata:
  triggers: Python, FastAPI, Pydantic, Python API, async Python, Python backend, uv, ruff, Python 3.14
  related-skills: openapi-spec-generation, database-schema-designer, agentic-ai-dev
  domain: backend
  role: specialist
  scope: implementation
  output-format: code
last-reviewed: "2026-03-14"
---

## Iron Law

**NO FASTAPI ENDPOINT WITHOUT A PYDANTIC v2 INPUT MODEL — never trust raw request data; validate at the boundary, always**

# Python 3.14 Development Skill

## Code Conventions
- Use **Python 3.14** with type hints everywhere
- **FastAPI** for REST APIs, **Pydantic v2** for validation
- Async by default: `async def` endpoints, `asyncpg` for PostgreSQL
- Use `uv` for package management, `ruff` for linting, `mypy` for types
- Folder structure: `api/routes/ → services/ → repositories/ → models/`
- Tests: pytest + pytest-asyncio + httpx

## Quick Scaffold — New Python Project

```bash
# Using uv (preferred)
uv init my-service
cd my-service
uv add fastapi uvicorn pydantic pydantic-settings
uv add --dev pytest pytest-asyncio httpx ruff mypy

# Or using pip
mkdir my-service && cd my-service
python -m venv .venv
source .venv/bin/activate    # Windows: .venv\Scripts\activate
pip install fastapi uvicorn pydantic pydantic-settings
pip install -e ".[dev]"
```

## Reference Files

**Code templates and project config**: Read `reference/fastapi-templates.md` for FastAPI app structure, Pydantic models, route handlers, SQLAlchemy models, pytest fixtures, pyproject.toml template, Docker configuration, and common commands.

**Advanced patterns and profiling**: Read `reference/python-advanced-patterns.md` for performance profiling (cProfile, py-spy, memory_profiler), pytest-benchmark, property-based testing with Hypothesis, structural pattern matching, descriptors, and memory optimization techniques.

**Auth, security and authorization**: Read `reference/fastapi-auth-security.md` for JWT tokens (`python-jose`), bcrypt password hashing (cost 12), `OAuth2PasswordBearer` dependency injection, RBAC role hierarchy, PBAC permission maps, resource ownership checks, auth-specific rate limit configuration, and pytest auth test patterns.

**Error handling, retry, and circuit breakers**: Read `reference/fastapi-error-handling.md` for custom exception hierarchy (`AppError` → `NotFoundError`/`ValidationError`/`ExternalServiceError`), FastAPI exception handlers, async retry with `tenacity`, async circuit breaker with `circuitbreaker`, error logging context middleware, and pytest patterns for error paths.

**Backend service consistency patterns**: Read `reference/backend-service-patterns.md` for 12 mandatory patterns covering all `services/backend/<service>/` code: timing-safe internal secret guard (P1), fail-fast config fields (P2), structlog naming (P3), session ownership (P4), Pub/Sub singleton (P5), fire-and-forget (P6), Redis lifecycle (P7), DB count queries (P8), GCS URI validation (P9), shared auth helpers (P10), no hardcoded config (P11), DRY shared utilities (P12). Includes pre-commit grep gates and new/modified service checklists.

**Live E2E integration testing**: Read `reference/backend-live-e2e-standard.md` for why unit tests (ASGITransport + mocks) miss real integration bugs, the per-service test pattern (health, auth gate, fake JWT rejection, internal secret gate, input validation), auth ordering rules (FastAPI validates auth before Pydantic), HTTP method verification from OpenAPI spec, and the feedback loop for fixing live failures.

**Pub/Sub and Firestore messaging patterns**: Read `reference/pubsub-firestore-patterns.md` for the three canonical messaging patterns: Pattern A (fire-and-forget `asyncio.create_task` for informational events), Pattern B (transactional outbox with `SELECT FOR UPDATE SKIP LOCKED` for load-bearing events), Pattern C (Firestore status bus for real-time mobile UI). Includes decision tree, full implementation templates, subscriber patterns, and hard rules for each.

## Process

1. **Scaffold project structure** using uv or pip commands above
2. **Read reference files** when you need specific templates or configuration
3. **Create folder structure**: `src/my_service/` with subfolders `api/routes/`, `models/`, `services/`, `core/`
4. **Write main.py** using FastAPI app template with lifespan context manager
5. **Define Pydantic models** for request/response validation in `models/`
6. **Implement route handlers** in `api/routes/` with proper HTTP methods and status codes
7. **Add business logic** in `services/` layer (keep routes thin)
8. **Configure environment** using pydantic-settings in `core/config.py`
9. **Write tests** with pytest-asyncio and AsyncClient fixtures
10. **Format and type-check**: Run `ruff format`, `ruff check --fix`, and `mypy`

## Key Patterns

| Pattern | Implementation |
|---------|---------------|
| **Type hints** | Use everywhere: `def func(x: int) -> str:` |
| **Async by default** | All I/O-bound operations use `async def` and `await` |
| **Validation** | Pydantic models for all API inputs/outputs |
| **Config** | pydantic-settings with `.env` file support |
| **Dependency injection** | FastAPI `Depends()` for services and repositories |
| **Error handling** | Raise `HTTPException` with appropriate status codes |
| **Database** | SQLAlchemy 2.0+ with async session and `Mapped[]` types |
| **Testing** | pytest with fixtures, httpx AsyncClient, 80%+ coverage |

## Documentation Sources

Before generating code, consult these sources for current syntax and APIs:

| Source | URL / Tool | Purpose |
|--------|-----------|---------|
| Pydantic v2 | `https://docs.pydantic.dev/latest/llms-full.txt` | Model validation, Field constraints, settings |
| FastAPI / Python | `Context7` MCP | Latest FastAPI endpoints, dependencies, middleware |

## Error Handling

**API errors**: Always raise `HTTPException` with descriptive detail messages.

```python
from fastapi import HTTPException

if not user:
    raise HTTPException(status_code=404, detail="User not found")

if not has_permission:
    raise HTTPException(status_code=403, detail="Insufficient permissions")
```

**Validation errors**: Pydantic automatically returns 422 with validation details. Use `Field()` constraints for business rules.

**Database errors**: Catch SQLAlchemy exceptions in service layer and convert to appropriate HTTP exceptions.

```python
from sqlalchemy.exc import IntegrityError

try:
    await session.commit()
except IntegrityError:
    raise HTTPException(status_code=409, detail="Email already exists")
```

## Common Commands

```bash
uvicorn src.main:app --reload                          # Run dev server (hot reload)
pytest -q                                              # Run tests (quiet output)
pytest -q --cov=src --cov-report=term-missing          # Tests with coverage
ruff check --fix .                                     # Lint and auto-fix
ruff format .                                          # Format code
mypy src/                                              # Type check
alembic upgrade head                                   # Run pending migrations
alembic revision --autogenerate -m "description"       # Generate new migration
```

## Hard Prohibitions

- Use `str | None` union syntax (Python 3.10+), not `Optional[str]`
- Use `model_validator` for cross-field Pydantic validation, not ad-hoc `__init__` logic

## Background Worker Services

For Pub/Sub, Cloud Scheduler, or GCS-triggered workers (NOT FastAPI REST APIs):

- Use the `/scaffold-python-worker` command to create the service structure
- Entry point: `async def run_job(payload: dict) -> JobResult:` in `src/job.py`
- External clients (APIs, cloud services) MUST be injected — never instantiated inline
- All failures MUST be logged via structlog and surfaced as status records — never swallowed
- Required env vars MUST have NO defaults in config — missing values raise `ValidationError` at startup
- After implementation: dispatch `python-worker-reviewer` agent for review

## Post-Code Review

After writing Python code, dispatch these reviewer agents:
- `code-reviewer` — general quality, DRY, error handling
- `python-worker-reviewer` — if this is a background worker service (Pub/Sub/Cloud Scheduler/GCS): silent failures, client injection, DB access patterns, structlog usage, test coverage
- `security-reviewer` — input validation, auth, dependency audit
