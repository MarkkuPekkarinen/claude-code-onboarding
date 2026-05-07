# Python Backend Service Consistency Patterns

> Every `services/backend/<service>/` MUST follow every pattern in this file.
> Violations block PR merge — pre-commit gates enforce each rule automatically.

---

## Why This File Exists

Backend service consistency audits repeatedly find the same drift points appearing across
independent services. These patterns codify hard-learned lessons so they cannot re-appear
in new or modified services.

Load this file BEFORE writing any code in `services/backend/`.

---

## P1 — Internal Secret Guard (Security-Critical)

**Rule:** Internal endpoints (server-to-server, not user-facing) MUST use timing-safe
comparison. Never write `!=` or unguarded string comparison for secrets. Use a shared
factory that wraps `hmac.compare_digest`.

```python
# ✅ REQUIRED — timing-safe internal secret dependency
import hmac
from fastapi import Depends, Header, HTTPException


def make_internal_secret_dep(secret: str):
    """Factory: returns a FastAPI dependency that validates X-Internal-Secret."""
    def _check(x_internal_secret: str | None = Header(None, alias="X-Internal-Secret")) -> None:
        if not x_internal_secret or not hmac.compare_digest(
            x_internal_secret.encode(), secret.encode()
        ):
            raise HTTPException(status_code=403, detail="Forbidden")
    return _check

# Wire at module level (captures config once, not per request)
_require_secret = make_internal_secret_dep(settings.INTERNAL_API_SECRET)

@router.post("/internal/action", dependencies=[Depends(_require_secret)])
async def internal_action(...): ...

# ❌ BANNED — bare != comparison (timing attack)
if x != settings.SECRET: ...

# ❌ BANNED — route-body secret check (instantiates DB session before auth)
async def handler(request: Request, db=Depends(get_session)):
    secret = request.headers.get("X-Internal-Secret")
    if not secret or ...: raise HTTPException(403)
```

**Pre-commit gate:**
```bash
# Bare != comparison against a secret string in service routes
grep -rn "!= settings\.\|!= secret\b" services/backend/*/src/*/api/routes/ --include="*.py" \
  | grep -v "test_\|#" → must return 0
```

---

## P2 — Config: Required Fields Have No Default

**Rule:** Every secret or environment-specific value in `core/config.py` is a bare `str`
(or `Field(min_length=N)`). `str | None = None` is forbidden for any field that must be
present — it silently passes `None` to downstream callers and hides misconfiguration until
production.

```python
# ✅ REQUIRED — fails at startup (ValidationError) if env var absent
from pydantic import Field
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    INTERNAL_API_SECRET: str = Field(min_length=32)  # enforces length, no default
    DATABASE_URL: str                                  # required, no default
    PUBSUB_TOPIC_EVENTS: str = "my-service-events"    # operational default OK
    LOG_LEVEL: str = "INFO"                           # operational default OK

# ❌ BANNED — silently passes None to DB/Pub/Sub
    DATABASE_URL: str | None = None
# ❌ BANNED — secret with no minimum length
    INTERNAL_API_SECRET: str = "changeme"
```

**Allowed defaults** (non-sensitive operational values that are stable across environments):
- Pub/Sub topic names: `PUBSUB_TOPIC_X: str = "my-topic-name"`
- Ports: `PORT: int = 8080`
- Service names: `SERVICE_NAME: str = "my-service"`
- Log level: `LOG_LEVEL: str = "INFO"`

**Pre-commit gate:**
```bash
grep -rn "str | None = None" services/backend/*/src/*/core/config.py → must return 0
grep -rn "INTERNAL_API_SECRET.*=.*['\"]" services/backend/*/src/*/core/config.py → must return 0
```

---

## P3 — Logger Naming: Always `logger`, Never `log`

**Rule:** Every module uses `logger = structlog.get_logger(__name__)`. The name `log` is
forbidden — it shadows the Python stdlib `log` function and creates inconsistency.

```python
# ✅ REQUIRED — in every .py file that logs
import structlog
logger = structlog.get_logger(__name__)

# ❌ BANNED
log = structlog.get_logger(__name__)      # wrong name
log = structlog.get_logger("myservice")  # hardcoded name (use __name__)
logger = structlog.get_logger()          # missing __name__
```

**Pre-commit gate:**
```bash
grep -rn "^log = structlog" services/backend/ --include="*.py" → must return 0
grep -rn "structlog.get_logger()" services/backend/ --include="*.py" | grep -v "__name__" → must return 0
```

---

## P4 — Session Ownership: Service Layer Only

**Rule:** Routes NEVER call `session.add()`, `session.commit()`, or `session.rollback()`.
The service layer owns all DB mutations. Routes call service methods and translate
exceptions to HTTP responses.

```python
# ✅ REQUIRED — route layer (thin)
@router.post("/entities", status_code=201)
async def create_entity(
    data: EntityCreate,
    svc: EntityService = Depends(_entity_service),
) -> EntityResponse:
    entity = await svc.create(data)       # service owns commit
    return EntityResponse.model_validate(entity)

# ✅ REQUIRED — service layer owns commit
class EntityService:
    async def create(self, data: EntityCreate) -> Entity:
        entity = Entity(**data.model_dump())
        self._session.add(entity)
        await self._session.commit()      # ← commit lives here
        return entity

# ❌ BANNED — route calling session directly
@router.post("/entities")
async def create_entity(data: EntityCreate, session: AsyncSession = Depends(get_session)):
    entity = Entity(**data.model_dump())
    session.add(entity)
    await session.commit()                # route owns session mutation
```

**Pre-commit gate:**
```bash
grep -rn "session\.add\|session\.commit\|session\.rollback" \
  services/backend/*/src/*/api/routes/ --include="*.py" | grep -v "test_\|#.*Session-isolated" → must return 0
```

---

## P5 — Pub/Sub Publisher: `@lru_cache(maxsize=1)` Singleton

**Rule:** Pub/Sub `PublisherClient` is expensive to create. Every service that publishes
events must use a cached singleton factory, not a per-request or module-level mutable global.

```python
# ✅ REQUIRED
from functools import lru_cache
from google.cloud import pubsub_v1

@lru_cache(maxsize=1)
def _build_pubsub_publisher() -> pubsub_v1.PublisherClient:
    return pubsub_v1.PublisherClient()

# ❌ BANNED — module-level mutable global
_pubsub_publisher: pubsub_v1.PublisherClient | None = None
def _get_publisher():
    global _pubsub_publisher
    if _pubsub_publisher is None:
        _pubsub_publisher = pubsub_v1.PublisherClient()
    return _pubsub_publisher

# ❌ BANNED — per-request instantiation
async def publish_something():
    publisher = pubsub_v1.PublisherClient()   # new client per call — expensive
    publisher.publish(...)
```

**Pre-commit gate:**
```bash
grep -rn "PublisherClient()" services/backend/ --include="*.py" | grep -v "lru_cache\|test_\|#" → must return 0
```

---

## P6 — Fire-and-Forget Pub/Sub: Always `asyncio.create_task()`

**Rule:** Informational Pub/Sub publishes MUST be wrapped in `asyncio.create_task()`.
Never `await` the publish inside a route or service method — that couples Pub/Sub latency
to the HTTP response. Never `.result()` at the call site — that raises on failure.

```python
# ✅ REQUIRED
import asyncio

asyncio.create_task(
    _publish_event({
        "event_type": "entity.created",
        "entity_id": str(entity.id),
        "published_at": datetime.now(tz=UTC).isoformat(),
    })
)

# ❌ BANNED
await _publish_event(...)            # blocks response; Pub/Sub outage = service outage
publisher.publish(...).result()      # synchronous; raises on failure at call site
```

See `pubsub-firestore-patterns.md` for the full Pattern A/B/C decision tree.

---

## P7 — Redis Lifecycle: Startup/Shutdown Hooks

**Rule:** Redis client initialization belongs in `app.router.on_startup` hooks, not in route
dependencies or module-level singletons. Shutdown uses `contextlib.suppress(Exception)` — a
Redis close error must never crash shutdown.

```python
# ✅ REQUIRED — in main.py
import contextlib
import redis.asyncio as aioredis

async def _startup_redis() -> None:
    try:
        app.state.redis = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
        logger.info("redis_connected", url=settings.REDIS_URL)
    except Exception:
        logger.warning("redis_unavailable", url=settings.REDIS_URL, exc_info=True)
        app.state.redis = None          # service runs degraded, not crashed

async def _shutdown_redis() -> None:
    redis_client: aioredis.Redis | None = getattr(app.state, "redis", None)
    if redis_client is not None:
        with contextlib.suppress(Exception):
            await redis_client.aclose()

app.router.on_startup.append(_startup_redis)
app.router.on_shutdown.append(_shutdown_redis)

# ❌ BANNED — module-level Redis pool (crashes on import if Redis is down)
_redis: aioredis.Redis = aioredis.from_url(settings.REDIS_URL)

# ❌ BANNED — bare except/pass in shutdown (silent failure, no log)
async def _shutdown_redis():
    try:
        await redis_client.aclose()
    except:
        pass
```

Routes read Redis from `request.app.state.redis` — never from a module-level variable.

---

## P8 — Database Count Queries: `func.count()` Subquery

**Rule:** Never use `len(results)` to count rows — that fetches all rows first. Use SQLAlchemy
`func.count()` in a subquery so counting happens at the DB level.

```python
# ✅ REQUIRED
from sqlalchemy import func, select

count_q = select(func.count()).select_from(
    select(Entity).where(*filters).subquery()
)
total: int = (await session.execute(count_q)).scalar_one()

# ❌ BANNED — fetches all rows then counts in Python
all_rows = (await session.execute(select(Entity).where(*filters))).scalars().all()
total = len(all_rows)
```

---

## P9 — GCS URI Validation: Shared Helper + Bucket Allowlist

**Rule:** Any service that accepts a GCS URI from a client MUST validate it against a
bucket allowlist before using it. Never write the regex + allowlist check inline per service.
Centralize in a shared utility so bug fixes apply everywhere at once.

```python
# ✅ REQUIRED — shared utility + per-service wrapper
from functools import lru_cache
import re
import uuid

_GCS_URI_PATTERN = re.compile(
    r"^gs://(?P<bucket>[a-z0-9][a-z0-9\-]{1,61}[a-z0-9])/(?P<rest>.+)$"
)

@lru_cache(maxsize=1)
def _allowed_buckets() -> frozenset[str]:
    from .core.config import settings as _cfg
    return frozenset({_cfg.GCS_MY_BUCKET})

def validate_gcs_uri(uri: str, path_prefix: str | None = None) -> None:
    """Validate GCS URI against service bucket allowlist.

    Raises ValueError with a descriptive message on any validation failure.
    """
    m = _GCS_URI_PATTERN.match(uri)
    if not m:
        raise ValueError(f"Invalid GCS URI format: {uri!r}")
    bucket = m.group("bucket")
    if bucket not in _allowed_buckets():
        raise ValueError(f"Bucket {bucket!r} not in allowlist")
    if path_prefix and not m.group("rest").startswith(path_prefix):
        raise ValueError(f"URI must start with gs://{bucket}/{path_prefix}")

# ❌ BANNED — inline regex redefined per service file
_GCS_URI_RE = re.compile(r"^gs://...")  # duplicates shared utility
```

---

## P10 — Shared Auth Helpers: No Local Reimplementation

**Rule:** Never define local `_uid()`, `_db_uid()`, `_role()`, or `_actor_id()` functions
in individual service route files. Extract to a shared auth module used across all services.

```python
# ✅ REQUIRED — import from shared module
from services_shared.auth.route_helpers import get_actor_id, get_db_uid, get_role, get_uid

# ❌ BANNED — local reimplementation per service
def _uid(current_user: dict) -> str:
    uid = current_user.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Missing uid")
    return uid
```

**Pre-commit gate:**
```bash
grep -rn "def _uid\|def _db_uid\|def _role\|def _actor_id" \
  services/backend/*/src/*/api/routes/ --include="*.py" → must return 0
```

---

## P11 — No Hardcoded URLs, Project IDs, or Bucket Names

**Rule:** Every URL, project ID, or bucket name that differs between environments MUST
come from environment variables. Hardcoded defaults in `core/config.py` silently route to
wrong resources in staging/production.

```python
# ✅ REQUIRED — env-varying values are required bare str (fail at startup if absent)
class Settings(BaseSettings):
    DATABASE_URL: str           # required — no default; differs per env
    GOOGLE_CLOUD_PROJECT: str   # required — no default
    EMAIL_FROM: str             # required — domain differs per env

# ❌ BANNED — hardcoded GCP project ID silently routes to wrong project
class Settings(BaseSettings):
    GOOGLE_CLOUD_PROJECT: str = "my-project-dev"

# ❌ BANNED — localhost fails inside Docker Compose (resolves to the container itself)
    REDIS_URL: str = "redis://localhost:6379/0"

# ❌ BANNED — os.getenv sentinel fallback bypasses Pydantic validation
    project = os.getenv("GOOGLE_CLOUD_PROJECT") or "my-project"
```

**Pre-commit gate:**
```bash
# Hardcoded localhost for services that differ between environments
grep -rn '"redis://localhost\|"http://localhost' services/backend/*/src/*/core/config.py → must return 0

# os.getenv with sentinel fallback in service code
grep -rn 'os\.getenv.*or\s*"' services/backend/ --include="*.py" \
  | grep -v "test_\|#" → must return 0
```

---

## P12 — DRY Shared Utilities: No Inline Duplication of Shared Logic

**Rule:** Any logic that exists in a shared service library MUST be imported from there.
Never define local copies. Common targets for duplication:

- GCS URI validation (P9 above)
- Pub/Sub `topic_path` builder
- Auth helpers (P10 above)

```python
# ✅ REQUIRED — import shared Pub/Sub topic path builder
from services_shared.utils.pubsub_utils import topic_path as _build_topic_path

def _topic_path(topic: str) -> str:
    return _build_topic_path(settings.GOOGLE_CLOUD_PROJECT, topic)

# ❌ BANNED — inline f-string that duplicates shared utility
def _topic_path(project_id: str, topic: str) -> str:
    return f"projects/{project_id}/topics/{topic}"
```

---

## New Service Checklist (run before opening any PR adding a new backend service)

```
□ P1: /internal/* endpoints use timing-safe secret comparison — no bare != against secrets
□ P2: core/config.py — required fields have no default; INTERNAL_API_SECRET uses Field(min_length=32)
□ P3: Every .py file uses logger = structlog.get_logger(__name__) — zero log = structlog occurrences
□ P4: Routes contain zero session.add/commit/rollback calls — service layer owns all mutations
□ P5: Pub/Sub publisher wrapped in @lru_cache(maxsize=1) factory
□ P6: All fire-and-forget publishes use asyncio.create_task() — zero await publish at route/service level
□ P7: Redis lifecycle in on_startup/on_shutdown hooks; contextlib.suppress in shutdown
□ P8: Count queries use func.count() subquery — zero len(results.all()) patterns
□ P9: Any GCS URI input validated against bucket allowlist before use
□ P10: Auth helpers imported from shared module — zero local reimplementations
□ P11: No hardcoded URLs, project IDs, or bucket names in config.py — all from env vars
□ P12: No inline duplication of shared utilities (GCS regex, topic path builders, auth helpers)
□ All pre-commit grep gates above pass before opening PR
```

---

## Modified Service Checklist (run on every PR touching an existing backend service)

```
□ Changed file respects all patterns above — run the relevant grep gates
□ New endpoint with /internal/ → P1 gate (timing-safe secret comparison)
□ New config field that is required → P2 gate (no str|None=None)
□ New module-level logger → P3 gate (logger = structlog.get_logger(__name__))
□ New DB write in route → P4 gate (must move to service layer)
□ New Pub/Sub publish → P5 (singleton) + P6 (create_task) gates
□ New Redis usage → P7 gate (startup/shutdown hooks, app.state.redis)
□ New count query → P8 gate (func.count() subquery)
□ New GCS URI input → P9 gate (validate against allowlist before use)
□ New auth helper → P10 gate (import from shared, not local def)
□ New config field with URL, project ID, or bucket → P11 gate (from env, not hardcoded)
□ New duplication of shared logic → P12 gate (import from shared utilities)
```
