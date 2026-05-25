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
| Context Precision | Are relevant chunks ranked near the **top** of retrieved set? | As soon as you add a reranker |
| MRR | 1 / rank of first relevant | Q&A where first hit matters |
| NDCG@K | Ranking quality with graded relevance | Search-style ordering |
| Hit@K | Any relevant doc in top-K? | Coarse baseline |

**Context Precision vs Precision@K:** Precision@K asks "how many of the top-K are relevant?" — binary. Context Precision asks "are the relevant chunks ranked near position 1 or buried at position K?" A reranker can leave Precision@K unchanged while dramatically improving Context Precision. Add this metric as soon as you introduce a reranker — it's the clearest signal of whether the reranker is earning its keep.

**Formula:** `Context Precision@K = Σ (Precision@i × relevance_i) / total_relevant` where `i` ranges over positions 1..K and `relevance_i` is 1 if chunk at position i is relevant, 0 otherwise.

## Eval Breakdown by Dimension

When Recall@K or another metric regresses — especially after a corpus growth event — **never treat the aggregate metric as the diagnosis**. Break it down first. The aggregate may hide a regression in one segment while other segments stay healthy.

Dimensions to slice by before touching the pipeline:

| Dimension | How to slice | What a drop isolates |
|---|---|---|
| **Document type** | policy vs. ticket vs. manual vs. table | Chunking or parsing problem specific to one format |
| **Recency** | fresh docs (< 30 days) vs. stale docs (> 90 days) | Freshness/version filtering issue; stale docs flooding top-K |
| **Query style** | keyword-heavy vs. semantic / conceptual | Embedding model weakness on one query style; BM25 not covering the other |
| **Query length** | short (≤ 5 tokens) vs. long (≥ 15 tokens) | Short queries may need expansion; long queries may need decomposition |
| **Corpus segment** | department, product line, access tier | Index crowding in one segment; wrong routing; missing sub-index |
| **Near-duplicate rate** | queries where top-3 results are near-identical | Corpus has duplicate/stale documents polluting top-K |

**Rule:** if one dimension shows a sharp drop while others are flat, the root cause is in that segment — fix that segment before changing the global pipeline. See `rag-operations-guide.md §9` for corpus hygiene fixes when duplicates or stale docs are the culprit.

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
| False Abstention Rate | How often the system refused when retrieved context actually supported an answer |
| False Answer Rate | How often the system answered when it should have abstained (the dangerous failure) |

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

## Diagnostic Matrix

When a metric regresses, use this table to triage the root cause before touching any code. Fix the upstream layer first — don't patch generation when retrieval is broken.

| Bad Metric | Likely Root Cause | Where to Look First |
|---|---|---|
| Low **Recall@K** | Bad chunking (chunks too large/small), weak embedding model, indexing gap, metadata filter too strict | Check chunking strategy, embedding model selection, pre-filter logic |
| Low **Precision@K** | Too many irrelevant chunks retrieved, reranker missing or weak, k too high | Reduce k, add/tune reranker, tighten hybrid retrieval |
| Low **Context Precision** | Reranker missing or underperforming — relevant chunks exist but are buried | Reranker not deployed, or `ef_search`/`nprobe` index params too loose; tune or add cross-encoder |
| Low **Context Relevance** | Semantic drift between query and document vocabulary, poor chunking, wrong retrieval strategy | Check query expansion, embedding model mismatch, chunking granularity |
| Low **Answer Relevance** | Prompt issue, generation model too weak, instructions unclear or conflicting | Audit system prompt, check for prompt injection, try stronger model |
| Low **Faithfulness** | Hallucination, citation enforcement absent in prompt, grounding prompt too weak | Add atomic-claim citation check, tighten grounding instructions, check context packing for noise |

**Key principle:** trace backward from the bad metric to the pipeline layer that owns it. Low Faithfulness is almost always a generation-layer or context-packing problem, not a retrieval problem. Low Recall@K is almost always a retrieval or chunking problem — fixing the prompt won't help.

## How to apply

When asked about RAG evaluation:

1. **Find out their phase.** v1 (no eval yet) needs golden set first. v2 (has eval) needs scale and calibration.
2. **Push back on "we'll evaluate later."** No golden set = flying blind. Even 50 queries beats nothing.
3. **Start with retrieval metrics, not just answer metrics.** Recall@K catches retrieval failures that look like generation failures.
4. **Warn against uncalibrated LLM-as-judge.** It's the most common eval mistake.
5. **Recommend per-claim citation checking** — citation presence is a weak signal.

Reference: full playbook §33–37 (evaluation), §35.2 (citation quality), §37.1 (eval at scale).
