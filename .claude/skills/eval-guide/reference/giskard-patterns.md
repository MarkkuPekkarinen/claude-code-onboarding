# Giskard OSS v3 Patterns

> **Verify via Context7 (`giskard`) before using.** These patterns reflect API state as of 2026-04-28.
> **v3 only** — v2 API (RAGET, giskard.scan) is legacy and NOT used.

## Install

```toml
# services/ai-shared/pyproject.toml
giskard = ">=3.0.0"   # pin to v3+ — NOT v2; verify exact version via Context7
# No LangChain dependency — verify: `pip show giskard | grep Requires` must not contain langchain
```

## Day-1 Smoke Test — Run Before Writing Any Giskard Code

```bash
# Verify Giskard v3 + LiteLLM Gemini integration works on your setup
python -c "
from giskard.agents import Generator, set_default_generator
set_default_generator(Generator(model='google/gemini-3.1-flash'))
print('Giskard v3 + Gemini: OK')
"
# If this fails: check GOOGLE_API_KEY env var and that giskard>=3.0.0 is installed
```

## Gemini Judge Setup

```python
from giskard.agents import Generator, set_default_generator

# Giskard v3's Generator routes through LiteLLM internally.
# LiteLLM's Google provider prefix: "google/gemini-3.1-flash"
# This is different from ADK model string ("gemini-3.1-flash") — include the "google/" prefix
set_default_generator(Generator(model="google/gemini-3.1-flash"))

# Call this ONCE per test session (e.g., in conftest.py session fixture)
# Best practice: use the same LLM provider as your main stack
```

## Scenario Fluent API — Core Pattern

```python
from giskard.checks import (
    Scenario, Suite, Trace,
    Groundedness, AnswerRelevance, Toxicity, Conformity, LLMJudge,
    SemanticSimilarity, StringMatching, RegexMatching,
    AllOf, AnyOf, Not
)

# Basic scenario: lease Q&A grounding check
result = await (
    Scenario("qa_agent_grounding")
    .interact(
        "What does my document say about X?",
        lambda inputs: your_qa_agent.run(inputs)
    )
    .check(Groundedness(
        name="answer_grounded_in_lease",
        answer_key="trace.last.outputs",
        context=retrieved_lease_chunks      # list of strings from RAG
    ))
    .check(AnswerRelevance(
        name="answer_addresses_question",
        question_key="trace.last.inputs",
        answer_key="trace.last.outputs"
    ))
    .run()
)
# result.passed → bool
# result.final_trace → full conversation history
```

## Policy Compliance Scenario

```python
# Test that your agent triggers the required policy detector for restricted criteria
policy_result = await (
    Scenario("policy_restricted_criteria_detection")
    .interact(
        "Apply criteria that may violate your policy",
        lambda inputs: your_agent.run(inputs)
    )
    .check(Conformity(
        name="policy_flag_set",
        rule="The agent must set the required review flag and not create any rule \
              containing restricted criteria."
    ))
    .check(Not(StringMatching(
        name="no_restricted_criteria_stored",
        pattern="<your restricted terms here>"
    )))
    .run()
)
# policy_result.passed must be True — this is a CI BLOCKER
```

## Suite — Multiple Scenarios

```python
from giskard.checks import Suite

suite = Suite("triage_agent_security")
suite.add(prompt_injection_scenario)
suite.add(fha_scenario)
suite.add(cross_tenant_scenario)

suite_results = await suite.run()
suite_results.to_junit_xml("reports/giskard/your_agent.xml")
```

## Deterministic Checks (No LLM Required)

```python
# For structural validation that doesn't need LLM-as-judge
from giskard.checks import StringMatching, RegexMatching, SemanticSimilarity

# Verify tenant ID not leaked in response
.check(Not(RegexMatching(
    name="no_tenant_id_leak",
    pattern=r"tenant_id:\s*\w+"    # CI BLOCKER — cross-tenant data leak
)))

# Verify urgency classification format
.check(StringMatching(
    name="urgency_valid_value",
    pattern="Emergency|High|Medium|Low"
))
```

## ⚠️ RAGET and giskard.scan — v2 Legacy, NOT v3

```python
# ❌ FORBIDDEN — these are v2 APIs, do NOT use
# from giskard.rag import generate_testset, KnowledgeBase  # v2 only
# giskard.scan(model, dataset)  # v2 only

# ✅ CORRECT — v3 Scenario/Suite API (shown above)
```

## Known Gotchas

| Gotcha | Fix |
|--------|-----|
| LiteLLM Google prefix is `google/` not empty | Use `Generator(model="google/gemini-3.1-flash")` — the slash-prefixed form |
| v2 RAGET (`generate_testset`) imported accidentally | Only import from `giskard.checks` and `giskard.agents` — never `giskard.rag` |
| `giskard.scan()` called — that's v2 | Use `Scenario.run()` or `Suite.run()` in v3 |
| Async test setup with pytest | Use `asyncio_mode = "auto"` in pyproject.toml; see `reference/pytest-harness.md` |
| `context` param in Groundedness must be list of strings | Split retrieved documents into individual strings before passing |
