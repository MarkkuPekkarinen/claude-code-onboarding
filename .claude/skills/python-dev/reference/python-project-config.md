# Python Project Configuration Templates

## pyproject.toml Template
```toml
[project]
name = "my-service"
version = "0.1.0"
requires-python = ">=3.14"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",
    "pydantic>=2.10.0",
    "pydantic-settings>=2.6.0",
    "sqlalchemy[asyncio]>=2.0.0",
    "asyncpg>=0.30.0",
    "alembic>=1.14.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.24.0",
    "httpx>=0.28.0",
    "ruff>=0.8.0",
    "mypy>=1.13.0",
]

[tool.ruff]
target-version = "py314"
line-length = 100
select = ["E", "F", "I", "N", "UP", "B", "SIM", "RUF"]

[tool.mypy]
python_version = "3.14"
strict = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

## Docker Template
```dockerfile
FROM python:3.14-slim

WORKDIR /app
RUN pip install uv

COPY pyproject.toml ./
RUN uv sync --no-dev

COPY src/ ./src/
EXPOSE 8000
CMD ["uv", "run", "uvicorn", "src.my_service.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Common Commands
```bash
# Run dev server
uvicorn src.my_service.main:app --reload --port 8000

# Run tests
pytest -v

# Lint and format
ruff check src/ --fix
ruff format src/

# Type check
mypy src/

# Alembic migrations
alembic init alembic
alembic revision --autogenerate -m "create users table"
alembic upgrade head
```
