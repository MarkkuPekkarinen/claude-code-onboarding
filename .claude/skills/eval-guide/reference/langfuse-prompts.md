# Langfuse Prompt Management

> **Verify via Context7 (`langfuse`) before using.** These patterns reflect API state as of 2026-04-28.

## Install

```toml
# services/ai-shared/pyproject.toml
langfuse = ">=2.0.0"   # pin to latest stable after Context7 verification
openinference-instrumentation-google-adk = ">=0.1.0"  # ADK→Langfuse OTel bridge
```

## Local Docker Stack

```bash
# Start Langfuse + its dependencies (6 containers)
docker compose -f infra/docker-compose.yml --env-file .env \
  --profile prompt-registry up -d
# Services: ClickHouse, PostgreSQL (separate from app PG), MinIO, Redis, Web, Worker
# UI: http://localhost:3000
```

## Prompt Naming Convention

```
<user_type>.<domain>.<task>.<prompt_type>

Examples:
  user.onboarding.profile_collection.system
  admin.onboarding.policy_extraction.system
  worker.onboarding.certification_extraction.system
  request.triage.classification.system
  request.triage.followup_questions.system
  search.matching.ranking.system
  review.comparison.system
  notification.user.status_update.system
  chat.rag_answer.system
  ui.form_generation.system
```

## PromptRegistry Abstraction — REQUIRED Pattern

**Never call Langfuse SDK directly from agent code.** All agents use `PromptRegistry`:

```python
# services/ai-shared/src/your_project/prompts/registry.py
import os
from functools import lru_cache
from typing import Literal
from langfuse import Langfuse

PromptLabel = Literal["development", "staging", "production"]

class PromptRegistry:
    """
    Abstraction layer over Langfuse SDK.
    Fail-closed: falls back to YAML in repo if Langfuse unreachable.
    Cache TTL: ~5 minutes to reduce Langfuse load.
    """
    
    def __init__(self):
        self._langfuse: Langfuse | None = None
        self._fail_closed = os.getenv("PROMPT_FAIL_CLOSED", "false").lower() == "true"
        self._cache: dict = {}
    
    def get_prompt(self, name: str, label: PromptLabel = "production") -> str:
        """Fetch and compile a prompt by name and label."""
        cache_key = f"{name}:{label}"
        if cache_key in self._cache:
            return self._cache[cache_key]
        
        try:
            lf = self._get_langfuse()
            prompt = lf.get_prompt(name, label=label)
            compiled = prompt.compile()
            self._cache[cache_key] = compiled
            return compiled
        except Exception as e:
            if self._fail_closed:
                return self._load_from_yaml(name)
            raise
    
    def compile(self, name: str, label: PromptLabel = "production", **variables) -> str:
        """Fetch prompt and compile with Mustache variables."""
        try:
            lf = self._get_langfuse()
            prompt = lf.get_prompt(name, label=label)
            return prompt.compile(**variables)
        except Exception:
            if self._fail_closed:
                return self._compile_from_yaml(name, **variables)
            raise
    
    def _get_langfuse(self) -> Langfuse:
        if self._langfuse is None:
            self._langfuse = Langfuse()  # reads LANGFUSE_* env vars
        return self._langfuse
    
    def _load_from_yaml(self, name: str) -> str:
        """Emergency fallback: load from prompts/ directory in repo."""
        import pathlib, yaml
        path = pathlib.Path(f"prompts/{name.replace('.', '/')}.yaml")
        return yaml.safe_load(path.read_text())["content"]
    
    def _compile_from_yaml(self, name: str, **variables) -> str:
        content = self._load_from_yaml(name)
        for key, value in variables.items():
            content = content.replace("{{" + key + "}}", str(value))
        return content


# Singleton — import this in agent code
prompt_registry = PromptRegistry()
```

## Agent Usage Pattern

```python
# In any ADK agent — ALWAYS use PromptRegistry, NEVER inline f-strings
from your_project.prompts.registry import prompt_registry

class TriageAgent:
    async def triage(self, request_description: str, tenant_id: str) -> TriageOutput:
        # Fetch system prompt by name + label (never "latest")
        system_message = prompt_registry.compile(
            "request.triage.classification.system",
            label="production",
            issue_description=request_description,
            priority_options="Critical, High, Medium, Low"
        )
        # Use system_message in agent...
```

## Prompt Lifecycle — Promotion Model

```
prompts/<domain>/<task>.system.yaml  ← Git (source of truth, PR-reviewed)
        ↓  make seed-prompts-local / seed-prompts-staging
Langfuse prompt registry             ← Runtime registry (versioned, label-routed)
        ↓  get_prompt(name, label="production")
Agent at runtime                     ← Fetches by label (NEVER "latest")
        ↓  trace records prompt_name + version
Phoenix / Cloud Trace                ← Incident triage by prompt version
```

**Label flow:** `development` → eval passes → `staging` → staging eval passes + human approval → `production`

**Rollback:** Move `production` label back to prior version — do NOT delete versions.

## What Goes in Code vs Langfuse

| In code (deterministic, security) | In Langfuse (language behavior, tunable) |
|----------------------------------|------------------------------------------|
| Tenant isolation checks | System prompts |
| Authorization middleware | Task prompts |
| Policy violation detectors | Notification tone prompts |
| Tool schemas (Pydantic) | Rubric / evaluator prompts |
| Business rules (escalation logic, scoping rules) | RAG answer instructions |
| Retry / fallback logic | UI generation prompts |
| Deterministic SQL filters | Prompt experiments |

## Drift Detection

```python
# scripts/prompts/diff_langfuse_prompts.py
# Compares 3 sources:
# 1. Git prompt hash — sha256 of prompts/<name>.yaml
# 2. Langfuse prompt metadata.content_hash — written at seed time
# 3. Langfuse prompt at production label — what's actually serving

# Run pre-release: make diff-prompts-staging / make diff-prompts-production
# Cadence: nightly in staging (alert on drift), weekly in production
```

## Emergency Prompt Pack Policy

| Mode | Trigger | Behavior |
|------|---------|---------|
| **Normal** | Langfuse healthy | Fetch by `production` label; cache last-known-good |
| **Degraded** | Langfuse unreachable, cache hit | Serve from in-process cache; emit `langfuse_degraded_total` metric; SEV-3 alert |
| **Emergency** | Langfuse unreachable, cache miss | Serve from bundled emergency pack baked into container image; emit `langfuse_emergency_total`; SEV-2 alert |

Emergency pack = YAML files from `prompts/` frozen at container build time. Never the latest unreviewed edits.

## Required env vars

```
LANGFUSE_PUBLIC_KEY=
LANGFUSE_SECRET_KEY=
LANGFUSE_HOST=http://localhost:3000   # local; http://langfuse:3000 in Docker; Cloud URL in staging/prod
LANGFUSE_INIT_ORG_ID=                # headless CI init
LANGFUSE_INIT_PROJECT_NAME=your-project
LANGFUSE_INIT_PROJECT_PUBLIC_KEY=
LANGFUSE_INIT_PROJECT_SECRET_KEY=
PROMPT_FAIL_CLOSED=false              # true in staging/prod
```

## Known Gotchas

| Gotcha | Fix |
|--------|-----|
| `langfuse.flush()` missing in eval scripts | Always call `langfuse.flush()` at end of eval scripts — SDK batches events; without it events are lost |
| Accessing `prompt.prompt` directly | Always call `prompt.compile()` — never access raw content directly |
| `label="latest"` used | Never use `"latest"` — always use `"development"`, `"staging"`, or `"production"` |
| Langfuse 6-container stack cold start | First boot takes longer — ClickHouse + PG need schema bootstrap; wait for all 6 containers healthy |
