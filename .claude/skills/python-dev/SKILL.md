---
name: python-dev
description: This skill provides patterns and templates for Python 3.13 development with FastAPI and modern tooling. It should be activated when creating Python APIs, scripts, data processing pipelines, or pytest tests.
allowed-tools: Bash, Read, Write, Edit
---

# Python 3.13 Development Skill

## Code Conventions
- Use **Python 3.13** with type hints everywhere
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
