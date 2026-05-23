# CI Eval Tiers (R1-R4)

> Source: `docs/architecture/eval-tooling-strategy.md`

## Tier Structure

| Tier | When it runs | What runs | Hard fail behavior |
|------|-------------|-----------|-------------------|
| **R1 — PR fast-gate** | Every PR touching `services/ai/**`, `mcp/**`, `prompts/**`, `tests/golden/**` | Critical Promptfoo cases; tenant-isolation Pytest suite; FHA-bypass cases; MCP auth/security smoke; A2UI schema validation | **Block merge.** No override without security-engineer approval recorded in PR. |
| **R2 — Nightly** | Nightly cron against staging | Full Promptfoo declarative suite; full Giskard scan; full MCP contract/auth/behavior/security suite; full RAG leakage cases; A2UI fuzz | Page security on-call on any new attack-success case. Fail-and-document, don't block. |
| **R3 — Pre-release** | Release candidate before staging→prod label move | Full red-team + golden-dataset baseline comparison + Vertex GenAI Eval rubric pass + security engineer sign-off | **Block release** on any regression of a critical case. |
| **R4 — Production canaries** | Synthetic traffic in production | Multi-tenant data-leak canary (hourly); FHA compliance canary (daily); prompt-injection canary (hourly); MCP unauthorized-tool-call canary (hourly) | Page on any non-zero `tenant_isolation_violation_total`; SEV-2 on any FHA/prompt-injection success. |

## Pytest Marks

```python
# Apply these marks to every eval test — never leave tests unmarked
import pytest

@pytest.mark.r1        # Critical — runs on every PR, must be < 5 min total
@pytest.mark.r2        # Full suite — runs nightly
@pytest.mark.r3        # Pre-release — Giskard / red-team scans (slow)
@pytest.mark.r4        # Production canary — runs every 6h against staging (skip locally without creds)
@pytest.mark.smoke     # Fast sanity — < 30s
@pytest.mark.integration  # Requires running Docker stack
@pytest.mark.eval      # Any LLM eval (may call Gemini API)

# Examples:
@pytest.mark.r1        # security case — always blocks PR
@pytest.mark.r2        # nightly only — slow or expensive
@pytest.mark.r1
@pytest.mark.smoke     # fast critical case
```

## pyproject.toml Marks Configuration

```toml
# pyproject.toml (root)
[tool.pytest.ini_options]
asyncio_mode = "auto"
markers = [
    "r1: Tier R1 fast-gate — runs on every PR (critical blocking cases only)",
    "r2: Tier R2 nightly — full eval suite",
    "r3: Tier R3 pre-release — Giskard / red-team scans (slow, blocking release)",
    "r4: canary / production smoke",
    "smoke: Fast subset — no external API calls, < 30s",
    "integration: Requires running Docker stack (make up)",
    "eval: LLM eval — may call Gemini API",
]
```

## GitHub Actions Path Routing

```yaml
# .github/workflows/eval-r1.yml
name: Eval R1 Fast Gate
on:
  pull_request:
    paths:
      - 'services/ai/**'
      - 'mcp/**'
      - 'prompts/**'
      - 'tests/golden/**'

jobs:
  r1-eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run R1 pytest gate
        run: uv run pytest -m "r1" --tb=short --junit-xml=reports/pytest-r1.xml -n auto
      - name: Run R1 Promptfoo
        run: npx promptfoo eval -c tests/eval/promptfoo/ --fail-on-error
      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: r1-eval-results
          path: reports/
```

## R1 CI Commands (run locally before PR)

```bash
# Fast gate — what GitHub Actions runs on every PR
make eval-smoke                              # < 30s
uv run pytest -m "r1" --tb=short -n auto    # critical pytest cases
npx promptfoo eval -c tests/eval/promptfoo/triage-agent.yaml --fail-on-error
npx promptfoo eval -c tests/eval/promptfoo/mcp-security.yaml --fail-on-error
```

## 9 Hard CI Blockers

These cases must always be in `tests/golden/security/` and covered by `@pytest.mark.r1`:

1. Tenant A accessing Tenant B's data
2. Prompt injection steering agent to unintended tool call
3. Policy bypass creating a restricted entity without the required review flag
4. MCP cross-tenant input ID accepted
5. MCP unauthorized tool call succeeds
6. RAG cross-tenant chunk retrieval
7. Structured output fails JSON-Schema validation
8. Write tool ships without audit-log call
9. New agent/MCP tool has zero red-team cases

**Any of these = merge blocked, no exceptions.**
