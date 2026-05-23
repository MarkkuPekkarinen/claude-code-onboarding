# Ragas Patterns

> **Verify via Context7 (`ragas`) before using.** These patterns reflect API state as of 2026-04-28.

## Install

```toml
# services/ai-shared/pyproject.toml
ragas = ">=0.2.0"   # pin to latest stable after Context7 verification
# Prefer not adding langchain or langchain-* as a dependency — use the LangChain-free path
```

## LangChain-Free Path — Preferred

```python
# ✅ CORRECT — use generate() directly, no LangChain
from ragas import evaluate
from ragas.dataset_schema import SingleTurnSample

# ❌ AVOID — requires LangChain, adds unnecessary dependency
# from ragas import TestsetGenerator
# generator.generate_with_langchain_docs(docs, ...)
```

## Gemini Judge Configuration

```python
# Query Context7 for exact llm_factory API before using
# Pattern: configure Ragas to use your preferred LLM as the evaluation judge
# Best practice: use the same LLM provider as your main stack for consistency
```

## Key Metrics

| Metric | Use | Typical agent(s) |
|--------|-----|----------|
| `ToolCallAccuracy(strict_order=True)` | Validates tool call sequence where order matters | Triage agents, retrieval agents |
| `AgentGoalAccuracyWithReference` | Validates agent achieved stated goal against golden reference | Matching agents, scheduling agents |
| `AgentGoalAccuracyWithoutReference` | Validates goal achieved without needing golden answer | Scheduling agents |
| `TopicAdherence(mode="precision")` | Validates agent stays within tenant's own data scope | Dashboard agents, scoped agents |
| `Faithfulness` | RAG faithfulness ≥ 0.9 | Messaging agents, QA agents |
| `ContextPrecision` | Retrieved chunks are relevant | Retrieval agents, QA agents |
| `ContextUtilization` | Reference-free context utilization check | Any RAG agent without golden reference |
| `FactualCorrectness(mode="f1")` | Claim decomposition vs golden reference answers | QA agents |

> **Verify all metric class names and constructor signatures via Context7 before writing code.**
> `answer_relevancy` is NOT a confirmed metric name in current Ragas API — use `ContextUtilization` instead.

## Pytest Integration Pattern

```python
import pytest
from datasets import Dataset  # verify Dataset import via Context7

@pytest.mark.r2   # nightly — RAG evals are slower
@pytest.mark.eval
async def test_qa_agent_faithfulness(qa_agent_runner):
    # Run agent against golden question
    result = await qa_agent_runner.run("What does my document say about X?")
    
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
# Validates that tool calls occur in the correct order
# strict_order=True enforces the sequence — use for agents with sequential tool dependencies

# Query Context7 for exact ToolCallAccuracy constructor signature
# Typical threshold: ToolCallAccuracy >= 0.9 (see per-agent-thresholds.md)
```

## Known Gotchas

| Gotcha | Fix |
|--------|-----|
| `generate_with_langchain_docs()` requires LangChain | Use `generate()` path only — never the LangChain variant |
| `answer_relevancy` may not exist in current API | Use `ContextUtilization` (reference-free) instead |
| Ragas async evaluation may conflict with pytest-asyncio | Set `asyncio_mode = "auto"` in pyproject.toml; see `reference/pytest-harness.md` |
| Some Ragas metrics require `ground_truth` in dataset | For reference-free metrics use `AgentGoalAccuracyWithoutReference` or `ContextUtilization` |

## Minimum Thresholds (from per-agent-thresholds.md)

Replace example agent names with your project's actual agents.

| Agent | Metric | Threshold |
|-------|--------|-----------|
| Triage agents with sequential tools | `ToolCallAccuracy(strict_order=True)` | ≥ 0.9 |
| Retrieval / matching agents | `ToolCallAccuracy(strict_order=True)` | ≥ 0.9 |
| Retrieval / matching agents | `ContextPrecision` | See per-agent-thresholds.md |
| Messaging agents | `Faithfulness` | ≥ 0.9 |
| QA agents | `Faithfulness` | ≥ 0.9 |
| QA agents | `ContextPrecision` | ≥ 0.8 |
| QA agents | `FactualCorrectness(mode="f1")` | ≥ 0.85 |
