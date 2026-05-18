---
name: rag-evaluator
description: Use when designing, building, or operating RAG evaluation — golden sets, retrieval metrics (Recall@K, NDCG, MRR), answer metrics (faithfulness, citation accuracy), LLM-as-judge setup, CI gates for RAG, eval at scale, drift detection. Triggers on phrases like "evaluate RAG", "golden set", "RAG metrics", "RAGAS", "faithfulness evaluation", "regression test RAG", "RAG CI".
---

# RAG Evaluation

Evaluation is what separates a RAG demo from a RAG product. Build evaluation **before** tuning the system, not after.

## Three levels of evaluation

| Level | What it measures |
|---|---|
| Retrieval | Did we fetch the right evidence? |
| Answer | Did the model generate a correct, grounded response? |
| Operational | Latency, cost, abstention rate, drift |

You need all three. Skipping retrieval evaluation is the most common mistake — teams measure answers and miss that retrieval was the actual problem.

## v1 vs v2 evaluation maturity

| Phase | Approach |
|---|---|
| **v1 (launch)** | 50–200 hand-labeled golden queries; retrieval metrics (Recall@K, NDCG); human spot checks; simple faithfulness rubric |
| **v2 (scale)** | LLM-as-judge calibrated against human labels; production-trace eval; synthetic eval generation; drift detection |

**Critical:** do not start with LLM-as-judge. Build the hand-labeled foundation first; an uncalibrated judge gives confident garbage.

## Retrieval metrics

| Metric | Measures | Use when |
|---|---|---|
| Recall@K | Fraction of relevant docs in top-K | High-stakes / compliance |
| Precision@K | Fraction of top-K that are relevant | Reducing noise |
| MRR | 1 / rank of first relevant | Q&A where first hit matters |
| NDCG@K | Ranking quality with graded relevance | Search-style ordering |
| Hit@K | Any relevant doc in top-K? | Coarse baseline |

## Answer metrics

| Metric | Measures |
|---|---|
| Faithfulness | Every claim supported by retrieved context? |
| Answer relevance | Does the answer address the question? |
| Context relevance | Was retrieved context actually useful? |
| Citation accuracy | Do citations support the claims? |
| Citation quality (≠ presence) | Does the cited chunk contain the *specific* assertion? |
| Hallucination rate | Frequency of unsupported assertions |
| Abstention quality | Refusals when refusal was correct |

## Citation quality is not citation presence

A common failure: 100% of answers have citations, but 30% of citations don't actually support the specific claim. Build evaluation that checks per-claim support:

```yaml
- query: "What insurance is required for HVAC vendors?"
  claim: "HVAC vendors need $1M liability insurance"
  citation_must_support:
    - vendor_type: HVAC
    - requirement_type: liability_insurance
    - minimum_amount: $1M
  failing_citations:
    - Generic vendor insurance discussion without HVAC specificity
    - Discussion of insurance without amount
```

## Golden set design

Build the golden set BEFORE building the system. Minimum viable golden set:

```yaml
- question: What insurance is required for HVAC vendors?
  expected_documents:
    - vendor-policy.pdf#page=12
  expected_sections:
    - Insurance Requirements
  expected_answer_contains:
    - general liability insurance
    - certificate of insurance
  must_not_contain:
    - unsupported cost estimate
  expected_classification: policy_question
  expected_abstention: false
```

**Coverage targets:**
- ~60% happy path (typical queries with clear answers)
- ~20% edge cases (rare terms, multi-hop, comparisons)
- ~20% known unanswerable (verify abstention works)

Even 50 labeled queries is dramatically better than zero. Don't wait for perfection.

## LLM-as-judge: dangers and mitigations

When you move to LLM-as-judge at scale (RAGAS, TruLens, custom), know the biases:

| Bias | Mitigation |
|---|---|
| Position bias | Randomize position |
| Verbosity bias | Cap or normalize answer length |
| Self-preference bias | Use different model family for judge vs generator |
| Style bias | Score against rubric, not impression |

**Calibration is mandatory.** Sample 10% of judge-graded responses, have humans grade them, track judge–human agreement. If agreement drops below 80%, the judge is drifting; re-prompt or re-train.

## Eval at scale

| Approach | When |
|---|---|
| Hand-labeled golden set | Always, from day one |
| Synthetic eval generation | Expand coverage; verify 10% by hand |
| Production-trace eval | After 1+ month live; sample real queries, label, feed back |
| Drift detection | Monitor distribution shifts in queries, scores, abstention rate |
| Counterfactual eval | Test abstention works — remove answer doc, verify refusal |

## CI gate pattern

```python
# Eval CI gate (pseudocode)
def rag_ci_gate(pull_request):
    results = run_eval(golden_set, pull_request.code)
    if results.recall_at_10 < baseline.recall_at_10 - 0.02:
        fail("Recall@10 regression")
    if results.faithfulness < baseline.faithfulness - 0.02:
        fail("Faithfulness regression")
    if results.citation_quality < baseline.citation_quality - 0.05:
        fail("Citation quality regression")
    return pass
```

Run this on every PR that touches the RAG pipeline.

## Python + FastAPI eval scaffolding

When the user wants to set up evaluation in a Python/FastAPI project:

```
evals/
  golden_set.yaml          # Hand-labeled queries
  run_eval.py              # Eval runner
  metrics.py               # Retrieval + answer metrics
  judges.py                # LLM-as-judge (v2)
  baselines.json           # Baseline scores for CI comparison
  reports/                 # Per-run reports
```

Suggested libraries: `ragas` (with calibration), `deepeval`, or custom — depends on stack. The framework matters less than having the golden set and running it on every change.

## How to apply

When asked about RAG evaluation:

1. **Find out their phase.** v1 (no eval yet) needs golden set first. v2 (has eval) needs scale and calibration.
2. **Push back on "we'll evaluate later."** No golden set = flying blind. Even 50 queries beats nothing.
3. **Start with retrieval metrics, not just answer metrics.** Recall@K catches retrieval failures that look like generation failures.
4. **Warn against uncalibrated LLM-as-judge.** It's the most common eval mistake.
5. **Recommend per-claim citation checking** — citation presence is a weak signal.

Reference: full playbook §33–37 (evaluation), §35.2 (citation quality), §37.1 (eval at scale).
