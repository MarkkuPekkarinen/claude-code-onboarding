# Ragas Patterns — PropertyHarbor

> **Verify via Context7 (`ragas`) before using.** These patterns reflect API state as of 2026-04-28.
> Source: `docs/architecture/eval-tooling-strategy.md` lines 350-437.

## Install

```toml
# services/ai-shared/pyproject.toml
ragas = ">=0.2.0"   # pin to latest stable after Context7 verification
# Do NOT add langchain or langchain-* as a dependency — violates constraints §1
```

## LangChain-Free Path — MANDATORY

```python
# ✅ CORRECT — use generate() directly, no LangChain
from ragas import evaluate
from ragas.dataset_schema import SingleTurnSample

# ❌ FORBIDDEN — requires LangChain, violates constraints §1
# from ragas import TestsetGenerator
# generator.generate_with_langchain_docs(docs, ...)
```

## Gemini Judge Configuration

```python
# Query Context7 for exact llm_factory API before using
# Pattern: configure Ragas to use Gemini as the evaluation LLM
# Do NOT use OpenAI as judge — violates constraints §1
```

## Key Metrics for PropertyHarbor

| Metric | PropertyHarbor use | Agent(s) |
|--------|-------------------|----------|
| `ToolCallAccuracy(strict_order=True)` | Validates tool call sequence (classify_urgency BEFORE vendor lookup) | `triage_agent`, `matching_engine` |
| `AgentGoalAccuracyWithReference` | Validates agent achieved stated goal against golden reference | `matching_engine`, `scheduling_agent` |
| `AgentGoalAccuracyWithoutReference` | Validates goal achieved without needing golden answer | `scheduling_agent` |
| `TopicAdherence(mode="precision")` | Validates agent stays within tenant's own data scope | `portfolio_agent` |
| `Faithfulness` | RAG faithfulness ≥ 0.9 | `messaging_agent`, `lease_qa_agent` |
| `ContextPrecision` | Retrieved chunks are relevant | `matching_engine`, `lease_qa_agent` |
| `ContextUtilization` | Reference-free context utilization check | Any RAG agent without golden reference |
| `FactualCorrectness(mode="f1")` | Claim decomposition vs golden reference answers | `lease_qa_agent` |

> **Verify all metric class names and constructor signatures via Context7 before writing code.**
> `answer_relevancy` is NOT a confirmed metric name in current Ragas API — use `ContextUtilization` instead.

## Pytest Integration Pattern

```python
import pytest
from datasets import Dataset  # verify Dataset import via Context7

@pytest.mark.r2   # nightly — RAG evals are slower
@pytest.mark.eval
async def test_lease_qa_faithfulness(lease_qa_runner):
    # Run agent against golden question
    result = await lease_qa_runner.run("What is the late fee in my lease?")
    
    # Build Ragas dataset
    data = {
        "question": ["What is the late fee in my lease?"],
        "answer": [result.text],
        "contexts": [result.retrieved_chunks],
        "ground_truth": ["The late fee is $50 after a 5-day grace period per Section 4.2"]
    }
    dataset = Dataset.from_dict(data)
    
    # Evaluate — query Context7 for exact evaluate() signature before using
    # from ragas import evaluate
    # from ragas.metrics import faithfulness
    # results = evaluate(dataset, metrics=[faithfulness])
    # assert results["faithfulness"] >= 0.9
```

## ToolCallAccuracy — Sequence Validation

```python
# Validates that classify_urgency is called BEFORE vendor_search_vendors
# strict_order=True enforces the sequence — order matters for triage

# Query Context7 for exact ToolCallAccuracy constructor signature
# Source: eval-tooling-strategy.md confirms strict_order=True parameter exists
# triage_agent threshold: ToolCallAccuracy >= 0.9 (per-agent-thresholds.md)
# matching_engine threshold: ToolCallAccuracy >= 0.9
```

## Known Gotchas (PropertyHarbor-specific)

| Gotcha | Fix |
|--------|-----|
| `generate_with_langchain_docs()` requires LangChain | Use `generate()` path only — never the LangChain variant |
| `answer_relevancy` may not exist in current API | Use `ContextUtilization` (reference-free) instead |
| Ragas async evaluation may conflict with pytest-asyncio | Set `asyncio_mode = "auto"` in pyproject.toml; see `reference/pytest-harness.md` |
| Some Ragas metrics require `ground_truth` in dataset | For reference-free metrics use `AgentGoalAccuracyWithoutReference` or `ContextUtilization` |

## Minimum Thresholds (from per-agent-thresholds.md)

| Agent | Metric | Threshold |
|-------|--------|-----------|
| `triage_agent` | `ToolCallAccuracy(strict_order=True)` | ≥ 0.9 |
| `matching_engine` | `ToolCallAccuracy(strict_order=True)` | ≥ 0.9 |
| `matching_engine` | `ContextPrecision` | See per-agent-thresholds.md |
| `messaging_agent` | `Faithfulness` | ≥ 0.9 |
| `lease_qa_agent` | `Faithfulness` | ≥ 0.9 |
| `lease_qa_agent` | `ContextPrecision` | ≥ 0.8 |
| `lease_qa_agent` | `FactualCorrectness(mode="f1")` | ≥ 0.85 |
