# ADK Project Configuration

## 1. pyproject.toml

```toml
[project]
name = "my-adk-service"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "google-adk>=1.0.0",
    "google-genai>=1.0.0",
    "fastapi>=0.128.0",
    "uvicorn[standard]>=0.30.0",
    "pydantic>=2.0.0",
    "pydantic-settings>=2.0.0",
    "structlog>=24.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "httpx>=0.27.0",
    "ruff>=0.4.0",
    "mypy>=1.10.0",
]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]

[tool.mypy]
strict = true
python_version = "3.11"

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

---

## 2. .env Template

```
GOOGLE_API_KEY=your-gemini-api-key-here
GOOGLE_CLOUD_PROJECT=your-gcp-project-id
GOOGLE_CLOUD_LOCATION=us-central1
APP_NAME=my-adk-service
LOG_LEVEL=INFO
```

Never commit `.env` to version control. Add it to `.gitignore`.

---

## 3. Config Module (pydantic-settings)

```python
# src/config.py
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    google_api_key: str
    google_cloud_project: str = ""
    google_cloud_location: str = "us-central1"
    app_name: str = "my-adk-service"
    log_level: str = "INFO"

    model_config = {"env_file": ".env"}


settings = Settings()
```

Import `settings` wherever config values are needed — do not read `os.environ`
directly in application code.

---

## 4. Directory Structure

```
my-adk-service/
+-- src/
|   +-- config.py             # pydantic-settings config
|   +-- main.py               # FastAPI app
|   +-- agents/
|   |   +-- __init__.py
|   |   +-- my_agent.py       # Agent definitions
|   +-- tools/
|   |   +-- __init__.py
|   |   +-- my_tools.py       # Tool functions
|   +-- api/
|   |   +-- __init__.py
|   |   +-- routes.py         # FastAPI routes
+-- tests/
|   +-- test_my_agent.py
+-- pyproject.toml
+-- .env
+-- Dockerfile
+-- docker-compose.yml
```

---

## 5. Dockerfile

Multi-stage build using `uv` for dependency resolution. Final image uses
`python:3.11-slim` with no build tools.

```dockerfile
FROM python:3.11-slim AS builder
WORKDIR /app
RUN pip install uv
COPY pyproject.toml .
RUN uv sync --no-dev

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /app/.venv .venv
COPY src/ src/
ENV PATH="/app/.venv/bin:$PATH"
ENV GOOGLE_API_KEY=""
EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Pass secrets at runtime via environment variables or a secrets manager — never
bake them into the image.

---

## 6. Structured Logging Setup

Use `structlog` for all logging. Never use `print()` or raw `logging.info()`.

```python
import structlog

log = structlog.get_logger()

# In tool functions:
log.info("tool_called", tool_name="my_tool", user_id="u123")
log.error("tool_failed", tool_name="my_tool", error=str(e))

# In API routes:
log.info("request_received", path="/chat", session_id=session_id)
log.error("request_failed", path="/chat", error=str(e))
```

Configure structlog once at application startup in `src/main.py`:

```python
import structlog

structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.add_log_level,
        structlog.processors.JSONRenderer(),
    ]
)
```

---

## 7. Common Commands

```bash
uv run uvicorn src.main:app --reload      # Dev server with hot reload
adk web                                    # ADK built-in web UI (dev only)
uv run pytest -q                          # Run all tests
uv run ruff check --fix .                 # Lint and auto-fix
uv run mypy src/                          # Static type checking
```
