# FastAPI Templates, Code Patterns, and Project Configuration

This reference contains production-ready code templates and project configuration for Python 3.14 + FastAPI development.

## FastAPI App Template

```python
# src/my_service/main.py
from fastapi import FastAPI
from contextlib import asynccontextmanager
from .api.routes import user_router, health_router
from .core.config import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print(f"Starting {settings.app_name}")
    yield
    # Shutdown
    print("Shutting down")

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(health_router, prefix="/api/v1", tags=["health"])
app.include_router(user_router, prefix="/api/v1/users", tags=["users"])
```

## Pydantic Models Template

```python
# src/my_service/models/user.py
from pydantic import BaseModel, EmailStr, Field
from uuid import UUID, uuid4
from datetime import datetime

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)

class UpdateUserRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    email: EmailStr | None = None

class UserResponse(BaseModel):
    id: UUID
    email: str
    name: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
```

## Config with pydantic-settings

```python
# src/my_service/core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "My Service"
    debug: bool = False
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/mydb"
    secret_key: str = "change-me"

    model_config = {"env_file": ".env"}

settings = Settings()
```

## Route Handler Template

```python
# src/my_service/api/routes/users.py
from fastapi import APIRouter, HTTPException, Depends
from uuid import UUID
from ...models.user import CreateUserRequest, UserResponse
from ...services.user_service import UserService

router = APIRouter()

@router.get("/", response_model=list[UserResponse])
async def list_users(service: UserService = Depends()) -> list[UserResponse]:
    return await service.find_all()

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: UUID, service: UserService = Depends()) -> UserResponse:
    user = await service.find_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(request: CreateUserRequest, service: UserService = Depends()) -> UserResponse:
    return await service.create(request)
```

## SQLAlchemy Async Model

```python
# src/my_service/models/db/user.py
from sqlalchemy import String, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from uuid import UUID, uuid4
from datetime import datetime, timezone

class UserEntity(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
```

## Pytest Template

```python
# tests/test_users.py
import pytest
from httpx import AsyncClient, ASGITransport
from src.my_service.main import app

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

@pytest.mark.asyncio
async def test_create_user(client: AsyncClient):
    response = await client.post(
        "/api/v1/users",
        json={"email": "john@example.com", "name": "John Doe"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "john@example.com"

@pytest.mark.asyncio
async def test_create_user_invalid_email(client: AsyncClient):
    response = await client.post(
        "/api/v1/users",
        json={"email": "not-valid", "name": "Test"},
    )
    assert response.status_code == 422
```

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
