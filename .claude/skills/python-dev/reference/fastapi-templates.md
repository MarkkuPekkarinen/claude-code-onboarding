# FastAPI Templates, Code Patterns, and Project Configuration

This reference contains production-ready code templates and project configuration for Python 3.13 + FastAPI development.

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
requires-python = ">=3.13"
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
target-version = "py313"
line-length = 100
select = ["E", "F", "I", "N", "UP", "B", "SIM", "RUF"]

[tool.mypy]
python_version = "3.13"
strict = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

## Docker Template
```dockerfile
FROM python:3.13-slim

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

## Common Pitfalls & Anti-Patterns

### Pitfall 1: Calling asyncio.run() Inside an Async Context

`asyncio.run()` creates a new event loop and is designed as a top-level entry point. Calling it from inside an `async def` function — including a FastAPI route handler, a dependency, or an async test — raises `RuntimeError: asyncio.run() cannot be called from a running event loop` because an event loop is already running. This is the single most common mistake when transitioning from synchronous to async Python.

```python
# ❌ BAD — raises RuntimeError inside FastAPI route
@router.get("/items/{item_id}")
async def get_item(item_id: int) -> ItemResponse:
    # asyncio.run() cannot be called from a running event loop
    result = asyncio.run(fetch_item(item_id))
    return result

# ❌ BAD — same mistake in a helper called from async context
def sync_helper(item_id: int) -> ItemResponse:
    return asyncio.run(fetch_item(item_id))  # crashes if caller is async
```

```python
# ✅ GOOD — await coroutines directly inside async functions
@router.get("/items/{item_id}")
async def get_item(item_id: int) -> ItemResponse:
    result = await fetch_item(item_id)
    return result

# ✅ GOOD — asyncio.run() is only valid at the top-level entry point
if __name__ == "__main__":
    asyncio.run(main())
```

---

### Pitfall 2: Mixing Sync and Async Route Handlers Incorrectly

FastAPI handles `def` and `async def` route handlers differently. A `def` (sync) handler runs in a thread pool — it works but consumes a thread per request and can exhaust the pool under load. An `async def` handler that calls blocking I/O (the `requests` library, `time.sleep`, blocking file reads) blocks the event loop entirely, stalling all concurrent requests.

```python
# ❌ BAD — async def calling blocking I/O blocks the entire event loop
@router.get("/data")
async def get_data() -> dict:
    response = requests.get("https://api.example.com/data")  # blocks event loop
    time.sleep(1)                                             # blocks event loop
    return response.json()

# ❌ BAD — sync def with async I/O (asyncio not available in thread pool)
@router.post("/users")
def create_user(request: CreateUserRequest) -> UserResponse:
    user = await user_service.create(request)  # SyntaxError: can't await in def
    return user
```

```python
# ✅ GOOD — async def with non-blocking async I/O
@router.get("/data")
async def get_data() -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com/data")
    return response.json()

# ✅ GOOD — sync def for CPU-bound work (FastAPI runs it in a thread pool)
@router.post("/process")
def process_file(file_path: str) -> dict:
    result = run_cpu_intensive_computation(file_path)
    return {"result": result}
```

---

### Pitfall 3: SQLAlchemy Async Session Misuse

Creating an `AsyncSession` directly inside a route instead of using dependency injection causes multiple sessions per request chain, broken transaction boundaries, and connection leaks. A related mistake is calling `session.commit()` inside a repository when the caller owns the transaction — this prevents the caller from composing multiple operations atomically.

```python
# ❌ BAD — creating a session manually inside the route
@router.post("/users")
async def create_user(request: CreateUserRequest) -> UserResponse:
    async with AsyncSession(engine) as session:   # new session, isolated transaction
        user = await user_repo.create(session, request)
        await session.commit()
    return user

# ❌ BAD — repository commits its own transaction (caller cannot compose)
class UserRepository:
    async def create(self, session: AsyncSession, data: CreateUserRequest) -> UserEntity:
        user = UserEntity(**data.model_dump())
        session.add(user)
        await session.commit()   # caller cannot wrap this in a larger transaction
        return user
```

```python
# ✅ GOOD — inject AsyncSession via Depends; session lifecycle managed by FastAPI
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

@router.post("/users", status_code=201)
async def create_user(
    request: CreateUserRequest,
    session: AsyncSession = Depends(get_db),
) -> UserResponse:
    user = await user_repo.create(session, request)
    return UserResponse.model_validate(user)

# ✅ GOOD — repository does NOT commit; caller controls the transaction boundary
class UserRepository:
    async def create(self, session: AsyncSession, data: CreateUserRequest) -> UserEntity:
        user = UserEntity(**data.model_dump())
        session.add(user)     # add() is sync — no await
        await session.flush() # flush to get generated ID without committing
        await session.refresh(user)
        return user
```

---

### Pitfall 4: Missing await on Async Coroutines

Calling an `async def` function without `await` does not execute it — it returns a coroutine object. No exception is raised at the call site; the call silently does nothing. This is especially dangerous for database writes. Note that `session.add()` is a sync method (no `await`), while `session.commit()`, `session.flush()`, and `session.execute()` are async and must be awaited.

```python
# ❌ BAD — coroutine is created but never executed (silent no-op)
@router.delete("/users/{user_id}", status_code=204)
async def delete_user(user_id: UUID, session: AsyncSession = Depends(get_db)) -> None:
    user_service.delete(user_id, session)   # missing await; delete never runs

# ❌ BAD — awaiting a sync method raises TypeError
async def save(session: AsyncSession, user: UserEntity) -> None:
    await session.add(user)    # TypeError: add() is not a coroutine
    await session.commit()
```

```python
# ✅ GOOD — await all async calls; do NOT await sync calls
@router.delete("/users/{user_id}", status_code=204)
async def delete_user(user_id: UUID, session: AsyncSession = Depends(get_db)) -> None:
    await user_service.delete(user_id, session)   # awaited correctly

async def save(session: AsyncSession, user: UserEntity) -> None:
    session.add(user)          # sync — no await
    await session.commit()     # async — must await

# ✅ GOOD — use asyncio.iscoroutine() in tests to catch missing awaits
import asyncio

def test_returns_coroutine_not_result():
    result = some_async_service.do_work()
    assert not asyncio.iscoroutine(result), "Forgot to await do_work()"
```

---

### Pitfall 5: Passing ORM Objects to Background Tasks

`BackgroundTasks.add_task()` schedules work to run after the HTTP response is sent. By that point, the request's database session has been closed and any ORM objects bound to it are in a detached state. Accessing lazy-loaded attributes or attempting to use them in queries raises `sqlalchemy.exc.DetachedInstanceError`.

```python
# ❌ BAD — user object is detached by the time background task runs
@router.post("/users", status_code=201)
async def create_user(
    request: CreateUserRequest,
    background_tasks: BackgroundTasks,
    session: AsyncSession = Depends(get_db),
) -> UserResponse:
    user = await user_service.create(session, request)
    background_tasks.add_task(send_welcome_email, user)  # session closed before task runs
    return UserResponse.model_validate(user)

async def send_welcome_email(user: UserEntity) -> None:
    # DetachedInstanceError: accessing user.email after session closed
    await email_client.send(to=user.email, subject="Welcome")
```

```python
# ✅ GOOD — pass only primitive values (IDs, strings) to background tasks
@router.post("/users", status_code=201)
async def create_user(
    request: CreateUserRequest,
    background_tasks: BackgroundTasks,
    session: AsyncSession = Depends(get_db),
) -> UserResponse:
    user = await user_service.create(session, request)
    background_tasks.add_task(send_welcome_email, str(user.id), user.email)
    return UserResponse.model_validate(user)

async def send_welcome_email(user_id: str, email: str) -> None:
    # Only primitives — no ORM session dependency
    await email_client.send(to=email, subject="Welcome")
```

---

### Pitfall 6: Mutating Pydantic v2 Models Directly

Pydantic v2 models are immutable by default when `model_config = ConfigDict(frozen=True)` is set — direct attribute assignment raises `ValidationError`. Even without `frozen=True`, direct mutation bypasses validators and is considered bad practice. Pydantic v2 replaced the v1 `.copy(update=...)` method with `.model_copy(update=...)`.

```python
# ❌ BAD — direct mutation raises ValidationError on frozen models
class UserResponse(BaseModel):
    model_config = ConfigDict(frozen=True)
    id: UUID
    email: str
    name: str

user = UserResponse(id=uuid4(), email="old@example.com", name="Alice")
user.email = "new@example.com"   # raises: ValidationError (frozen_instance)

# ❌ BAD — using deprecated Pydantic v1 .copy() method
updated = user.copy(update={"email": "new@example.com"})  # deprecated in v2
```

```python
# ✅ GOOD — use model_copy(update={...}) for Pydantic v2 immutable mutations
class UserResponse(BaseModel):
    model_config = ConfigDict(frozen=True)
    id: UUID
    email: str
    name: str

user = UserResponse(id=uuid4(), email="old@example.com", name="Alice")
updated = user.model_copy(update={"email": "new@example.com"})
# user is unchanged; updated has the new email

# ✅ GOOD — deep copy when nested models must also be independent
updated_deep = user.model_copy(update={"email": "new@example.com"}, deep=True)
```
