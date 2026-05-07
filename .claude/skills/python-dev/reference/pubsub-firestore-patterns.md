# Pub/Sub and Firestore Messaging Patterns

> Three canonical patterns. No ad-hoc alternatives.
> Apply the decision tree below before choosing any pattern.

---

## Quick Decision Tree

```
Crossing a process boundary?
    |
    +-- Is the consumer a mobile app needing real-time UI (e.g. via Firestore)?
    |       YES → Pattern C (Firestore status bus)
    |
    +-- Is the event load-bearing?
    |   (losing it = broken workflow — downstream action never triggered)
    |       YES → Pattern B (transactional outbox)
    |
    +-- Informational event — consumer benefits but caller doesn't depend on delivery
            YES → Pattern A (fire-and-forget Pub/Sub)
```

---

## Pattern A — Direct Fire-and-Forget Pub/Sub

**Use for:** Informational events where the caller does NOT depend on delivery.
Examples: `entity.created`, `entity.status_changed`, `document.uploaded`.

### Required implementation

```python
import asyncio
import json
from datetime import UTC, datetime
from functools import lru_cache

import structlog
from google.cloud import pubsub_v1

from ..core.config import settings

logger = structlog.get_logger(__name__)


@lru_cache(maxsize=1)
def _get_publisher() -> pubsub_v1.PublisherClient:
    """Lazy singleton — SDK is expensive to instantiate."""
    return pubsub_v1.PublisherClient()


def _topic_path(topic: str) -> str:
    return f"projects/{settings.GOOGLE_CLOUD_PROJECT}/topics/{topic}"


async def _publish_event(data: dict) -> None:
    """Fire-and-forget: logs on failure, never raises."""
    try:
        publisher = _get_publisher()
        encoded = json.dumps(data, default=str).encode()
        await asyncio.to_thread(
            lambda: publisher.publish(_topic_path(settings.PUBSUB_MY_TOPIC), encoded).result()
        )
        logger.info("pubsub_publish_ok", event_type=data.get("event_type"))
    except Exception:
        logger.error("pubsub_publish_failed", event_type=data.get("event_type"), exc_info=True)


# In the route/service — always create_task, never await directly
asyncio.create_task(
    _publish_event({
        "event_type": "entity.created",
        "entity_id": str(entity.id),
        "published_at": datetime.now(tz=UTC).isoformat(),
    })
)
```

### Hard rules

- ALWAYS wrap in `asyncio.create_task()` at the call site — never `await _publish_event()`
  inside a route or service method (this adds Pub/Sub latency to HTTP response time)
- ALWAYS catch all exceptions inside `_publish_event` — log and return, never raise
- NEVER use this pattern for events that trigger cross-service state changes (use Pattern B)
- Use `@lru_cache(maxsize=1)` for the publisher client — the GCP SDK is expensive to instantiate per request

---

## Pattern B — Transactional Outbox

**Use for:** Load-bearing events where losing the event breaks a downstream workflow.
Examples: `quote.approved` triggers job scheduling, `payment.captured` triggers fulfillment.

### Required implementation

**Step 1 — Outbox SQLAlchemy model** (in shared models):

```python
from sqlalchemy import DateTime, String, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class MyServiceEventsOutbox(Base):
    __tablename__ = "my_service_events_outbox"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    event_type: Mapped[str] = mapped_column(String(64), nullable=False)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # NULL = unpublished / pending retry; non-NULL = successfully published
```

**Step 2 — Write outbox row inside the state-change transaction**:

```python
async def approve_entity(self, entity_id: uuid.UUID, session: AsyncSession) -> Entity:
    entity = await session.get(Entity, entity_id, with_for_update=True)
    _validate_can_approve(entity)

    entity.status = "approved"
    outbox_row = MyServiceEventsOutbox(
        event_type="entity.approved",
        payload={
            "entity_id": str(entity.id),
            "approved_at": datetime.now(tz=UTC).isoformat(),
        },
        published_at=None,  # NULL = not yet published
    )
    session.add(outbox_row)
    await session.commit()      # both entity update + outbox row in one transaction
    # NO Pub/Sub call here — outbox processor handles it
    return entity
```

**Step 3 — Outbox processor** (called by Cloud Scheduler endpoint):

```python
async def process_outbox(
    session: AsyncSession,
    topic: str,
    batch_size: int = 50,
) -> list[str]:
    """Publish unpublished outbox rows. Returns IDs of successfully published rows."""
    rows = (
        await session.execute(
            select(MyServiceEventsOutbox)
            .where(MyServiceEventsOutbox.published_at.is_(None))
            .limit(batch_size)
            .with_for_update(skip_locked=True)   # safe for concurrent sweeps
        )
    ).scalars().all()

    published_ids: list[str] = []
    for row in rows:
        try:
            await publish_outbox_payload(
                topic=topic,
                event_type=row.event_type,
                payload=row.payload,
            )
            row.published_at = datetime.now(UTC)
            published_ids.append(str(row.id))
        except Exception:
            logger.error("outbox_publish_failed", row_id=str(row.id), exc_info=True)
            # Leave published_at NULL — next sweep will retry

    await session.commit()
    return published_ids
```

**Step 4 — publish_outbox_payload RAISES on failure** (unlike Pattern A):

```python
async def publish_outbox_payload(topic: str, event_type: str, payload: dict) -> str:
    """Raises on failure — caller must NOT set published_at if this raises."""
    publisher = _get_publisher()
    data = json.dumps({"event_type": event_type, **payload}, default=str).encode()
    message_id = await asyncio.to_thread(
        lambda: publisher.publish(_topic_path(topic), data).result()
    )
    logger.info("pubsub_outbox_publish_ok", event_type=event_type, message_id=message_id)
    return message_id
```

**Step 5 — Cloud Scheduler endpoint**:

```python
@router.post("/internal/process-outbox", include_in_schema=False)
async def process_outbox_endpoint(
    request: Request,
    session: AsyncSession = Depends(get_db),
) -> dict:
    _verify_internal_secret(request)
    published_ids = await process_outbox(session, topic=settings.PUBSUB_MY_TOPIC)
    return {"published_count": len(published_ids), "event_ids": published_ids}
```

### Hard rules

- NEVER publish inside the DB transaction (Pub/Sub failure rolls back the entity state)
- NEVER publish after `session.commit()` without an outbox row (event silently lost on failure)
- `publish_outbox_payload` MUST raise — the processor relies on the exception to leave
  `published_at` NULL for retry
- Use `SELECT … FOR UPDATE SKIP LOCKED` in the processor — safe for concurrent scheduler runs
- Outbox table belongs in shared migrations — not per-service

---

## Pattern C — Firestore Status Bus (backend side)

**Use for:** Real-time status updates to mobile clients (Flutter/React Native) that need
live streaming without polling. Only applies when Firestore is part of the stack.

> If your stack does not use Firestore, use WebSockets, SSE, or polling instead.
> Pattern C is Firestore-specific.

### Required implementation

```python
import asyncio
import uuid
from datetime import UTC, datetime

import structlog
from google.cloud import firestore

from ..core.config import settings

logger = structlog.get_logger(__name__)


async def write_status_event(
    resource_id: uuid.UUID,
    event_id: uuid.UUID,
    status: str,
    previous_status: str,
    actor_id: uuid.UUID | None,
    actor_type: str,
) -> None:
    """Write resource status change to Firestore (real-time status bus).

    Non-fatal: failures are logged but NEVER raised to the caller.
    The relational DB already committed the canonical state before this runs.
    """
    client: firestore.AsyncClient | None = None
    try:
        client = firestore.AsyncClient(project=settings.GOOGLE_CLOUD_PROJECT)
        doc_ref = (
            client.collection("resources")
            .document(str(resource_id))
            .collection("status_events")
            .document(str(event_id))
        )
        await doc_ref.set({
            "status": status,
            "previous_status": previous_status,
            "actor_id": str(actor_id) if actor_id else None,
            "actor_type": actor_type,
            "timestamp": datetime.now(tz=UTC).isoformat(),
        })
    except Exception:
        logger.error("firestore_status_write_failed", resource_id=str(resource_id), exc_info=True)
    finally:
        if client is not None:
            await client.close()


# In the route/service — always create_task, never await
asyncio.create_task(
    write_status_event(
        resource_id=resource_id,
        event_id=uuid.uuid4(),
        status=new_status,
        previous_status=previous_status,
        actor_id=actor_id,
        actor_type=actor_type,
    )
)
```

### Hard rules

- NEVER write canonical entity data to Firestore — status_events subcollection ONLY
- ALWAYS wrap in `asyncio.create_task()` — never `await write_status_event()` at call site
- ALWAYS catch all exceptions — Firestore failure must never surface to the HTTP caller
- The relational DB (PostgreSQL) remains canonical — Firestore is a write-through feed only
- Mobile clients read via `.snapshots()` stream listener, NOT one-time `.get()` calls

---

## Adding a New Topic — Required Steps

```bash
# 1. Add topic name to service config (operational default allowed)
class Settings(BaseSettings):
    PUBSUB_MY_TOPIC: str = "my-service-events"

# 2. Tri-file sync — all environment config files
# .env.example:    PUBSUB_MY_TOPIC=my-service-events
# .env.staging:    PUBSUB_MY_TOPIC=my-service-events
# .env.production: PUBSUB_MY_TOPIC=my-service-events

# 3. Local emulator init — add to Pub/Sub init script
curl -X PUT "http://pubsub-emulator:8085/v1/projects/$PROJECT/topics/my-service-events"

# 4. Verify
make check-env-sync    # must exit 0
make up                # new topic created on stack start
```

---

## Subscriber Pattern

```python
from google.cloud import pubsub_v1

def start_pubsub_consumer(subscription: str, dispatch_fn) -> pubsub_v1.SubscriberClient:
    """Streaming pull subscriber. Returns client for lifecycle management.

    # Fallback: if emulator unavailable, log and return — HTTP endpoints still work.
    """
    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(settings.GOOGLE_CLOUD_PROJECT, subscription)

    def callback(message: pubsub_v1.subscriber.message.Message) -> None:
        try:
            payload = json.loads(message.data.decode())
            asyncio.run_coroutine_threadsafe(dispatch_fn(payload), loop).result(timeout=30)
            message.ack()
        except Exception as exc:
            logger.error("pubsub_dispatch_failed", error=str(exc))
            message.nack()   # triggers redelivery

    try:
        subscriber.subscribe(subscription_path, callback=callback)
        logger.info("pubsub_consumer_started", subscription=subscription_path)
    except Exception as exc:
        logger.error("pubsub_consumer_failed", error=str(exc))

    return subscriber
```

**Hard rules for subscribers:**
- ALWAYS `ack()` on success, `nack()` on exception — no silent drops
- ALWAYS set a `timeout` on `run_coroutine_threadsafe().result()` — unbounded wait = thread leak
- NEVER process messages synchronously in the callback if the handler is async — use `run_coroutine_threadsafe`
