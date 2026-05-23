# Pytest Harness Configuration — PropertyHarbor

> Source: `docs/architecture/eval-tooling-strategy.md` lines 285-378.
> Verify `pytest-asyncio` version compatibility via Context7 before using.

## Required pyproject.toml Configuration

```toml
# pyproject.toml (root — all services inherit via uv workspace)
[tool.pytest.ini_options]
asyncio_mode = "auto"          # REQUIRED: all 14 agents are async
                               # eliminates @pytest.mark.asyncio decoration per test
                               # requires pytest-asyncio >= 0.21
testpaths = ["tests", "services"]
addopts = "--tb=short -q"

[tool.pytest.ini_options.markers]
r1 = "Tier R1 fast-gate — runs on every PR (critical blocking cases only)"
r2 = "Tier R2 nightly — full eval suite"
smoke = "Fast subset — no external API calls, < 30s"
integration = "Integration — requires running Docker stack"
eval = "LLM eval — may call Gemini API or ADK runner"
```

## Required Plugins

```toml
# services/ai-shared/pyproject.toml (or root)
[project.optional-dependencies]
eval = [
    "pytest-asyncio>=0.24",    # asyncio_mode = "auto" requires >= 0.21; pin to latest stable
    "pytest-mock>=3.14",       # tool failure injection (Dimension 13 fallback tests)
    "pytest-cov>=5.0",         # coverage gating (>= 85% line / >= 90% function)
    "pytest-xdist>=3.5",       # parallel execution (-n auto)
]
```

## conftest.py — Session-Scoped Fixtures

```python
# services/ai/conftest.py — shared by all agent eval suites
import pytest
from google.adk.runners import InMemoryRunner
from unittest.mock import AsyncMock

@pytest.fixture(scope="session")
def adk_runner():
    """Session-scoped InMemoryRunner — one instance for the whole eval session.
    Reuse across tests to avoid repeated initialization overhead.
    """
    return InMemoryRunner()

@pytest.fixture
def mock_mcp_tool():
    """Inject a failing MCP tool to test graceful degradation (Dimension 13).
    Per constraints §12: every ADK tool must have a defined fallback path.
    """
    return AsyncMock(side_effect=Exception("MCP tool unavailable — testing fallback"))

@pytest.fixture(scope="session")
def golden_cases(request):
    """Parametrize helper — yields cases from a golden .evalset.json file.
    Use with @pytest.mark.parametrize("case", golden_cases("path/to/evalset.json"))
    """
    import json, pathlib
    path = pathlib.Path(request.param)
    return json.loads(path.read_text())["evals"]
```

## Parametrize-Over-Golden Pattern

```python
# services/ai/triage_agent/tests/test_triage_evals.py
import pytest
import json
import pathlib

GOLDEN = json.loads(
    pathlib.Path("tests/golden/agents/triage_agent/golden.evalset.json").read_text()
)["evals"]

CRITICAL = json.loads(
    pathlib.Path("tests/golden/agents/triage_agent/critical_cases.evalset.json").read_text()
)["evals"]

@pytest.mark.parametrize("case", GOLDEN, ids=[c["name"] for c in GOLDEN])
@pytest.mark.r2                           # full suite — nightly only
async def test_triage_urgency(case, adk_runner):
    result = await adk_runner.run(case["query"]["content"])
    assert result.output["urgency"] == case.get("expected_urgency")
    assert result.output.get("confidence", 1.0) >= case.get("min_confidence", 0.0)

@pytest.mark.parametrize("case", CRITICAL, ids=[c["name"] for c in CRITICAL])
@pytest.mark.r1                           # BLOCKS PR — habitability 100% threshold
async def test_triage_critical_habitability(case, adk_runner):
    """Zero tolerance for missed habitability emergencies (gas leak, flood, no heat).
    100% threshold — a single miss is a blocking CI failure per constraints §10.
    """
    result = await adk_runner.run(case["query"]["content"])
    assert result.output["urgency"] == "Emergency", (
        f"Habitability emergency misclassified as {result.output['urgency']} — CI BLOCKER"
    )
```

## Tool Failure Injection (Fallback Testing)

```python
# Per constraints §12 + §26: every ADK tool must have a defined fallback path.
# Test it with pytest-mock:

@pytest.mark.r1    # critical — blocks PR if fallback breaks
async def test_classify_urgency_fallback(mock_mcp_tool, adk_runner, mocker):
    """When classify_urgency tool fails, agent must fall back gracefully."""
    mocker.patch(
        "ai_shared.tools.classify_urgency.call",
        side_effect=Exception("tool unavailable")
    )
    result = await adk_runner.run("Water heater leaking in unit 4B")
    # Fallback: needs_classification=True, status=Open (per constraints §12)
    assert result.output["needs_classification"] is True
    assert result.output["status"] == "Open"
    # Must NOT raise — fallback must produce a valid output
```

## Confidence Threshold Enforcement in @r1 Tests

When writing `@r1` golden manifest tests that check `confidence_min`, scope the rule to urgency classification cases only — NOT all agent golden cases:

```python
# ✅ CORRECT — filter on urgency before enforcing confidence threshold
def test_clear_cut_cases_have_tight_confidence_thresholds():
    for case in golden_cases:
        expected = case["expected_output"]
        if "urgency" not in expected:
            continue  # root_cause, pattern detection, non-urgency cases exempt
        assert expected.get("confidence_min", 0) >= 0.80

# ❌ WRONG — applies rule to all cases including root_cause (legitimately use 0.5)
def test_clear_cut_cases_have_tight_confidence_thresholds():
    for case in golden_cases:
        assert case["expected_output"].get("confidence_min", 0) >= 0.80
```

`root_cause` and pattern detection cases legitimately use `confidence_min=0.5` — pattern detection is probabilistic. Only urgency classification needs `>= 0.80`. Applying the urgency threshold to all case types causes false failures on legitimate golden data.

## CI Execution Commands

```bash
# Tier R1 — PR fast-gate (< 5 min total)
uv run pytest -m "r1" --tb=short --junit-xml=reports/pytest-r1.xml -n auto

# Tier R2 — Nightly (full suite)
uv run pytest -m "r2 or r1" --tb=long --junit-xml=reports/pytest-r2.xml -n 4

# Single agent only
uv run --package triage-agent pytest -m "r1" tests/

# Coverage report
uv run pytest --cov=services/ai --cov-report=term-missing --cov-fail-under=85
```

## asyncio_mode = "auto" — Why This Is Required

All 14 PropertyHarbor ADK agents are async. Without `asyncio_mode = "auto"`:
- Async test functions silently vacuously pass (no error, no actual execution)
- Collection errors on some pytest-asyncio versions
- Missing `@pytest.mark.asyncio` on every test causes cryptic failures

`asyncio_mode = "auto"` is the single pyproject.toml setting that prevents all of these.
Requires `pytest-asyncio >= 0.21` (pin to latest stable — verify via Context7).
