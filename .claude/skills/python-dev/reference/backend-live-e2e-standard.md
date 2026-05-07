# Backend Live E2E Integration Testing Standard

## Why Unit Tests Are Not Enough

`services/backend/<svc>/tests/` tests are **unit tests** — they use `ASGITransport(app=app)`
which bypasses the real HTTP stack, mock external service initialization, mock the database engine,
and use `AsyncMock()` for DB sessions. They never hit a real Docker container.

Unit tests CANNOT catch:
- Wrong HTTP method (PUT vs PATCH vs POST)
- Missing route prefixes (`/api/v1/`)
- Auth gate ordering (auth checked before validation)
- Container startup failures or port mismatches
- Real auth token rejection
- Cross-service integration issues

## The Live E2E Test Standard

**Location:** `tests/eval/test_backend_live_e2e.py`

This is the single canonical live E2E test file that covers all backend services.
It uses `httpx.AsyncClient(base_url="http://localhost:<port>")` with NO transport
override — hitting actual running Docker containers.

**Run command:** `make backend-e2e-live` (or `uv run pytest tests/eval/test_backend_live_e2e.py`)

**When to run:** MANDATORY before any PR touching `services/backend/` — run after
smoke tests confirm all containers are healthy.

## Per-Service Test Pattern

Every backend service MUST have these test cases in `tests/eval/test_backend_live_e2e.py`:

```python
# 1. Health check
async def test_<svc>_health(<svc>_client):
    r = await <svc>_client.get("/health")
    assert r.status_code == 200
    assert r.json()["service"] == "<service-name>"  # hyphenated name

# 2. Auth gate — no credentials → 401/403
async def test_<svc>_list_requires_auth(<svc>_client):
    r = await <svc>_client.get("/api/v1/<resources>")
    assert r.status_code in (401, 403)

# 3. Fake JWT rejection → 401
async def test_<svc>_create_with_fake_jwt_returns_401(<svc>_client):
    r = await <svc>_client.post(
        "/api/v1/<resources>",
        json={...},
        headers={"Authorization": _FAKE_JWT},
    )
    assert r.status_code == 401

# 4. Internal endpoint requires secret (for services with /internal/* routes)
async def test_<svc>_internal_requires_secret(<svc>_client):
    r = await <svc>_client.post(f"/api/v1/internal/<resources>/{uuid.uuid4()}/action")
    assert r.status_code in (401, 403)

# 5. Input validation — 422 on missing required fields
#    NOTE: Only testable if auth uses internal secret (not JWT Bearer).
#    If service uses JWT Bearer, auth is checked first → 401, not 422.
async def test_<svc>_create_missing_fields(<svc>_client):
    if not _INTERNAL_SECRET:
        pytest.skip("INTERNAL_API_SECRET not available in .env")
    r = await <svc>_client.post(
        "/api/v1/<resources>",
        json={},
        headers={_INTERNAL_SECRET_KEY: _INTERNAL_SECRET},
    )
    assert r.status_code == 422
```

## Adding Tests for a New Backend Service

When adding a new service under `services/backend/<service>/`:

1. Add a `@pytest.fixture` for the service client:
```python
@pytest_asyncio.fixture
async def <svc>_client() -> AsyncGenerator[httpx.AsyncClient, None]:
    async with httpx.AsyncClient(base_url=f"http://localhost:{<SVC>_PORT}") as client:
        yield client
```

2. Add port constant at top of file:
```python
<SVC>_PORT = int(os.getenv("<SERVICE_NAME>_PORT", "<default_port>"))
```

3. Add the 5 standard test cases (pattern above)

4. Add service to `_ALL_SERVICES` list in cross-service tests:
```python
_ALL_SERVICES = {
    ...,
    "<service-name>": f"http://localhost:{<SVC>_PORT}",
}
```

5. Add `<svc>_client` fixture to `test_all_services_are_reachable` params

## Critical Implementation Notes

### Auth Ordering
FastAPI validates auth BEFORE Pydantic schema. This means:
- JWT-protected endpoint + empty body → **401** (not 422)
- Internal-secret endpoint + correct secret + empty body → **422**

Always check actual auth mechanism from the service's OpenAPI spec before writing
input-validation tests.

### HTTP Methods
ALWAYS verify from `curl -s http://localhost:<port>/openapi.json` before writing tests.
Do NOT assume method from endpoint name:
- Status updates are typically PATCH, not PUT
- Internal scoring endpoints are POST, not PUT

### Route Prefix
Backend services commonly use an `/api/v1/` prefix. Internal routes often use
`/api/v1/internal/` prefix. Always verify from the OpenAPI spec — some services
may use different prefixes for admin or identity routes.

## Pre-commit Gate

```bash
# MANDATORY — run after smoke test confirms containers are healthy, before PR creation
make backend-e2e-live

# Equivalent direct command
uv run pytest tests/eval/test_backend_live_e2e.py -v --tb=short
```

All tests must pass. Any failure = fix before PR creation. Use the feedback loop:
1. Read the failure — check the actual OpenAPI spec at `http://localhost:<port>/openapi.json`
2. Fix the test OR fix the service code (if behavior is genuinely wrong)
3. Re-run `make backend-e2e-live`
4. Repeat until GREEN
