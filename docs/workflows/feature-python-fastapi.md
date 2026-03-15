# Feature Development — Python / FastAPI

> **When to use**: Building a new feature or endpoint in a Python 3.14 / FastAPI service
> **Time estimate**: 1–3 hours per feature
> **Prerequisites**: Approved spec in `docs/specs/`, approved plan in `docs/plans/` (see [`ideation-to-spec.md`](ideation-to-spec.md))

## Overview

Full Python/FastAPI feature lifecycle from scaffold through TDD to reviewed, security-cleared PR. Async by default, Pydantic v2 validated at boundaries, ruff-clean throughout.

## Phases

### Phase 1 — Project Scaffold (new projects only)

**Trigger**: No existing FastAPI project
**Command**: `/scaffold-python-api [project-name]`
**15-step process** (from `commands/scaffold-python-api.md`):
1. Create `.gitignore` first
2. Initialize project with `pyproject.toml`
3. Set up virtual environment with `uv` — see `uv-package-manager` skill for lockfile setup (`uv lock` + `uv sync --frozen`)
4. Create folder structure
5. Create `main.py` with FastAPI app
6. Create `config.py` with `pydantic-settings`
7. Create sample Pydantic model
8. Create sample route, service, repository
9. Add health check endpoint
10. Create test `conftest.py`
11. Add pytest test
12. Configure `ruff` and `mypy`
13. Create Dockerfile
14. Create `.env.example`
15. Run `pip audit` and print summary

**Produces**: Production-ready FastAPI service scaffold
**Gate**: `pytest` passes, `ruff check .` clean, `mypy .` clean

---

### Phase 1.5 — Architecture Decision (new features or unclear approach)

**Trigger**: Framework choice unclear, or async vs sync strategy not confirmed
**Skill**: `python-patterns`
**Decision checklist**:
- Framework: FastAPI (API-only) / Django (full-stack+admin) / Flask (simple/script)
- Async: Use `async def` for all I/O-bound FastAPI routes (workspace default)
- Structure: Layer-based (medium APIs) vs feature-based (5+ domain areas)
- Background tasks: `BackgroundTasks` (fire-and-forget) vs Celery/ARQ (distributed, retry)

**Gate**: Framework, async strategy, and structure confirmed before writing code

---

### Phase 2 — Load Skill

**Trigger**: About to implement any FastAPI feature
**Action**: Load `python-dev` skill (`skills/python-dev/SKILL.md`)
**MCP**: Context7 for FastAPI, Pydantic v2 current APIs

**8 key patterns** (from `skills/python-dev/SKILL.md:45-56`):
- **Type hints** — all function signatures, no implicit `Any`
- **Async by default** — `async def` for all route handlers and services
- **Validation** — Pydantic v2 models at all API boundaries
- **Config** — `pydantic-settings` with `BaseSettings`, env var injection
- **Dependency injection** — FastAPI `Depends()` for services, DB sessions
- **Error handling** — `HTTPException` with structured detail; never return raw strings
- **Database** — async SQLAlchemy with `AsyncSession`, or repository pattern
- **Testing** — `pytest-asyncio`, `httpx.AsyncClient` for E2E, `pytest-cov`

**Gate**: Skill loaded, MCP queried for any API signatures being used

**Also load**: `uv-package-manager` skill if setting up CI/CD or Docker for this service

---

### Phase 3 — TDD: Write Failing Test First

**Iron Law** (from `skills/test-driven-development/SKILL.md:16-21`): `NO IMPLEMENTATION WITHOUT A FAILING TEST FIRST`

**For Python** (from `skills/test-driven-development/references/tdd-patterns-python.md`):
- `pytest-asyncio` for async test functions
- `httpx.AsyncClient` with `ASGITransport` for endpoint tests
- `pytest.fixture` for shared setup
- `unittest.mock.AsyncMock` for mocking async dependencies

**Red-Green-Refactor**:
1. **Red** — Write pytest test that defines expected behaviour, confirm `FAILED`
2. **Green** — Minimum code to pass
3. **Refactor** — Clean structure (tests still green)

**Produces**: Failing test with correct assertion
**Gate**: `pytest <test_file>` shows `FAILED` (not error)

---

### Phase 3.5 — Test Infrastructure (new projects only)

**Trigger**: No `conftest.py` exists or test suite needs restructuring
**Skill**: `python-testing-patterns`
**Setup**:
1. Create `tests/conftest.py` with `AsyncClient` fixture
2. Configure `pyproject.toml` — `asyncio_mode = "auto"`, testpaths, markers
3. Add test markers: `@pytest.mark.slow`, `@pytest.mark.integration`
4. Set coverage gate: `--cov-fail-under=80`

**Gate**: `pytest -q` passes, `pytest --cov=src --cov-report=term-missing` shows coverage

---

### Phase 4 — Implement Feature

**Build order**:
1. Pydantic model → `src/<service>/models/<name>.py`
2. Request/Response schemas → `src/<service>/schemas/<name>.py`
   - Use `pydantic-models-py` skill for Base/Create/Update/Response model pattern
3. Repository → `src/<service>/repositories/<name>_repository.py`
4. Service → `src/<service>/services/<name>_service.py`
5. Router → `src/<service>/routers/<name>.py`
6. Register router in `main.py`

**Standards**:
- No `print()` — use `logging.getLogger(__name__)` with structured context
- No bare `except:` — always catch specific exceptions, log, and either raise or return error state
- All secrets via environment variables — never hardcoded
- Pydantic v2 `model_validator` for cross-field validation
- Async database sessions via `AsyncSession` context manager

**Produces**: Working feature, `pytest` passes
**Gate**: `pytest` green, `ruff check .` clean, `mypy .` clean

---

### Phase 5 — Review (run in parallel)

**Agent 1**: `code-reviewer`
- Vibe: *"Finds real bugs, not style preferences — ≥80% confidence before raising an issue"*
- Checks: general quality, patterns, DRY violations, unused imports

**Agent 2**: `silent-failure-hunter`
- Vibe: *"An empty catch block is not error handling — it's a lie to the operator"*
- Checks: bare `except`, `except Exception: pass`, missing error logging, silent fallbacks

**Agent 3**: `security-reviewer`
- Vibe: *"Assumes every input is hostile until the code proves otherwise"*
- Checks: input validation, SQL injection, secrets exposure, SSRF, path traversal

**Gate**: Zero CRITICAL findings; HIGH findings resolved or accepted

---

### Phase 6 — Pre-Commit Validation

**Command**: `/validate-changes`
**Agent**: `output-evaluator`
**Also run**: `pip audit` — zero high/critical CVEs

**Verdicts**: APPROVE → proceed | NEEDS_REVIEW / REJECT → fix and re-run
**Gate**: APPROVE + zero high CVEs

---

### Phase 7 — PR Review

**Command**: `/review-pr`
**6 roles**: comment-analyzer + pr-test-analyzer + silent-failure-hunter + type-design-analyzer + code-reviewer + code-simplifier
**Gate**: All CRITICAL + HIGH resolved

---

## Quick Reference

| Phase | What to Run | Produces | Gate |
|-------|-------------|----------|------|
| 1 — Scaffold | `/scaffold-python-api` | Full FastAPI skeleton | `pytest` passes |
| 2 — Load skill | `python-dev` + `uv-package-manager` | Pattern reference | MCP queried |
| 3 — TDD | Write failing pytest | Failing test | `FAILED` status |
| 3.5 — Test infra | `python-testing-patterns` | conftest.py, markers, coverage | `pytest -q` passes |
| 4 — Implement | model → schema → repo → service → router | Working code | `pytest` green |
| 5 — Review | `code-reviewer` + `silent-failure-hunter` + `security-reviewer` | Findings | Zero CRITICAL |
| 6 — Pre-commit | `/validate-changes` | APPROVE/NEEDS_REVIEW/REJECT | APPROVE |
| 7 — PR | `/review-pr` | 6-role review | CRITICAL+HIGH resolved |

---

## Common Pitfalls

- **Sync functions in async routes** — blocking calls in `async def` routes block the event loop; use `asyncio.to_thread()` for sync I/O
- **Pydantic v1 syntax** — this stack uses Pydantic v2; `@validator` is replaced by `@field_validator`, `orm_mode` by `model_config = ConfigDict(from_attributes=True)`
- **Missing `await`** — async SQLAlchemy calls without `await` return coroutines, not results
- **Bare `except`** — catches `KeyboardInterrupt` and `SystemExit`; always be specific
- **`print()` in production code** — bypasses log aggregation; use `logging`
- **Hardcoded secrets** — always `os.getenv()` or `pydantic-settings`

## Related Workflows

- [`ideation-to-spec.md`](ideation-to-spec.md) — spec and plan before implementation
- [`feature-agentic-ai.md`](feature-agentic-ai.md) — LangGraph/LangChain AI agents on FastAPI
- [`security-audit.md`](security-audit.md) — deeper security audit
- [`pr-shipping.md`](pr-shipping.md) — PR lifecycle after review
- `python-patterns` skill — architecture decisions before implementation
- `pydantic-models-py` skill — API schema design with multi-model pattern
- `uv-package-manager` skill — lockfiles, Docker, CI caching for Python projects
- `python-testing-patterns` skill — pytest infrastructure, fixtures, coverage config
- `python-packaging` skill — internal CLI tools and project structure
