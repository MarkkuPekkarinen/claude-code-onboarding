---
description: Scaffold a RAG evaluation setup — golden set template, eval runner, metrics, CI gate
---

# /rag-eval-init — Bootstrap RAG Evaluation

Scaffold a complete RAG evaluation setup. The goal is for the user to have something runnable within 30 minutes that catches regressions.

## Phase 1: Confirm context

Ask:
1. Where should `evals/` live? (default: repo root)
2. Python or another language? (default: Python — matches FastAPI / ADK stack)
3. Does a golden set already exist anywhere? (CSV, spreadsheet, Notion?)
4. Vector DB / retrieval entry point? (so the runner can hit it)

## Phase 2: Create the directory structure

```
evals/
  golden_set.yaml          # Hand-labeled queries
  run_eval.py              # Eval runner
  metrics.py               # Retrieval + answer metrics
  judges.py                # LLM-as-judge (v2, marked as not-yet-used)
  baselines.json           # Baseline scores for CI comparison
  reports/                 # Per-run reports (gitignored except .gitkeep)
  README.md                # How to add queries, run evals, interpret results
```

## Phase 3: Write the files

### `evals/golden_set.yaml`

Start with 10 placeholder queries spanning happy path / edge case / unanswerable. Show the schema clearly:

```yaml
# RAG Golden Set
# Target: 50+ queries before tuning the system
# Coverage: ~60% happy path, ~20% edge cases, ~20% known unanswerable

version: 1
queries:
  - id: q-001
    question: "REPLACE WITH A TYPICAL USER QUERY"
    category: happy_path
    classification: factual_lookup
    expected_documents:
      - "REPLACE: document_id or path"
    expected_sections:
      - "REPLACE: section name"
    expected_answer_contains:
      - "REPLACE: phrase that must appear"
    must_not_contain:
      - "REPLACE: phrase that must NOT appear (hallucination check)"
    expected_abstention: false

  - id: q-002
    question: "REPLACE WITH AN EDGE CASE — multi-hop or comparison"
    category: edge_case
    classification: comparison
    expected_documents:
      - doc-a
      - doc-b
    expected_answer_contains:
      - "REPLACE"
    expected_abstention: false

  - id: q-003
    question: "REPLACE WITH AN UNANSWERABLE QUERY"
    category: unanswerable
    expected_abstention: true
    abstention_reason_should_mention: "insufficient evidence"

  # ... add 7 more placeholders following the same pattern
```

### `evals/metrics.py`

Provide working implementations of Recall@K, Precision@K, MRR, NDCG@K, plus stubs for faithfulness and citation quality:

```python
"""Retrieval and answer metrics for RAG evaluation."""
from __future__ import annotations
from dataclasses import dataclass
from typing import Iterable
import math


@dataclass
class RetrievalResult:
    query_id: str
    retrieved_doc_ids: list[str]   # in rank order
    expected_doc_ids: set[str]


def recall_at_k(result: RetrievalResult, k: int) -> float:
    top_k = set(result.retrieved_doc_ids[:k])
    if not result.expected_doc_ids:
        return 1.0
    return len(top_k & result.expected_doc_ids) / len(result.expected_doc_ids)


def precision_at_k(result: RetrievalResult, k: int) -> float:
    top_k = result.retrieved_doc_ids[:k]
    if not top_k:
        return 0.0
    hits = sum(1 for d in top_k if d in result.expected_doc_ids)
    return hits / len(top_k)


def mrr(result: RetrievalResult) -> float:
    for i, doc_id in enumerate(result.retrieved_doc_ids, start=1):
        if doc_id in result.expected_doc_ids:
            return 1.0 / i
    return 0.0


def ndcg_at_k(result: RetrievalResult, k: int) -> float:
    def dcg(docs: list[str]) -> float:
        return sum(
            (1.0 if d in result.expected_doc_ids else 0.0) / math.log2(i + 1)
            for i, d in enumerate(docs[:k], start=1)
        )
    actual = dcg(result.retrieved_doc_ids)
    ideal_docs = list(result.expected_doc_ids)[:k]
    ideal = dcg(ideal_docs) if ideal_docs else 1.0
    return actual / ideal if ideal > 0 else 0.0


def context_precision_at_k(result: RetrievalResult, k: int) -> float:
    """Measures whether relevant chunks are ranked near the top of the retrieved set.

    Unlike Precision@k (binary: how many are relevant?), Context Precision rewards
    retrievers that put relevant chunks at positions 1-2 over those that bury them
    at positions 4-5. Critical signal for reranker quality.

    Formula: sum(Precision@i * rel_i for i in 1..k) / total_relevant_in_top_k
    """
    if not result.expected_doc_ids:
        return 1.0
    running_hits = 0
    precision_sum = 0.0
    for i, doc_id in enumerate(result.retrieved_doc_ids[:k], start=1):
        if doc_id in result.expected_doc_ids:
            running_hits += 1
            precision_sum += running_hits / i  # Precision@i
    return precision_sum / len(result.expected_doc_ids) if result.expected_doc_ids else 0.0


def aggregate(results: Iterable[RetrievalResult], k: int = 10) -> dict[str, float]:
    results = list(results)
    if not results:
        return {}
    return {
        f"recall@{k}":            sum(recall_at_k(r, k) for r in results) / len(results),
        f"precision@{k}":         sum(precision_at_k(r, k) for r in results) / len(results),
        f"context_precision@{k}": sum(context_precision_at_k(r, k) for r in results) / len(results),
        "mrr":                    sum(mrr(r) for r in results) / len(results),
        f"ndcg@{k}":              sum(ndcg_at_k(r, k) for r in results) / len(results),
    }


# Answer metrics — stub implementations
# Real faithfulness and citation_quality need an LLM judge (see judges.py)
# Defer these to v2; v1 should rely on retrieval metrics + human spot checks.

def answer_contains_check(answer: str, must_contain: list[str]) -> bool:
    return all(s.lower() in answer.lower() for s in must_contain)


def answer_does_not_contain_check(answer: str, must_not_contain: list[str]) -> bool:
    return not any(s.lower() in answer.lower() for s in must_not_contain)


def abstention_check(answer: str, expected_abstention: bool) -> bool:
    refusal_signals = [
        "i don't have",
        "i don't know",
        "not available in the provided",
        "insufficient evidence",
        "cannot determine",
    ]
    abstained = any(sig in answer.lower() for sig in refusal_signals)
    return abstained == expected_abstention
```

### `evals/run_eval.py`

A runner with a pluggable RAG callable:

```python
"""
RAG eval runner.

Usage:
    python -m evals.run_eval --rag-callable myapp.rag:answer
    python -m evals.run_eval --rag-callable myapp.rag:answer --update-baseline
"""
from __future__ import annotations
import argparse
import importlib
import json
import sys
from datetime import datetime
from pathlib import Path
import yaml

from evals.metrics import (
    RetrievalResult, aggregate,
    answer_contains_check, answer_does_not_contain_check, abstention_check,
)

EVAL_DIR = Path(__file__).parent
GOLDEN = EVAL_DIR / "golden_set.yaml"
BASELINES = EVAL_DIR / "baselines.json"
REPORTS = EVAL_DIR / "reports"

# CI gate thresholds — regression beyond this fails the build
REGRESSION_TOLERANCE = {
    "recall@10":    0.02,
    "ndcg@10":      0.02,
    "mrr":          0.02,
    "answer_contains_rate": 0.03,
    "abstention_correct_rate": 0.05,
}


def load_callable(spec: str):
    """Load a 'module.path:function' spec."""
    mod_path, func_name = spec.split(":")
    return getattr(importlib.import_module(mod_path), func_name)


def run(rag_callable, golden_path: Path) -> dict:
    with open(golden_path) as f:
        golden = yaml.safe_load(f)

    retrieval_results = []
    answer_pass = answer_fail = 0
    abstention_pass = abstention_fail = 0

    per_query = []
    for q in golden["queries"]:
        # The RAG callable must return: {"answer": str, "retrieved_doc_ids": [str], "abstained": bool}
        response = rag_callable(q["question"])

        # Retrieval check
        if q.get("expected_documents"):
            retrieval_results.append(RetrievalResult(
                query_id=q["id"],
                retrieved_doc_ids=response.get("retrieved_doc_ids", []),
                expected_doc_ids=set(q["expected_documents"]),
            ))

        # Answer content check
        contains_ok = answer_contains_check(
            response["answer"], q.get("expected_answer_contains", [])
        )
        not_contains_ok = answer_does_not_contain_check(
            response["answer"], q.get("must_not_contain", [])
        )
        if contains_ok and not_contains_ok:
            answer_pass += 1
        else:
            answer_fail += 1

        # Abstention check
        if abstention_check(response["answer"], q.get("expected_abstention", False)):
            abstention_pass += 1
        else:
            abstention_fail += 1

        per_query.append({
            "id": q["id"],
            "question": q["question"],
            "contains_ok": contains_ok,
            "not_contains_ok": not_contains_ok,
            "abstention_ok": abstention_check(response["answer"], q.get("expected_abstention", False)),
        })

    metrics = aggregate(retrieval_results, k=10)
    metrics["answer_contains_rate"] = answer_pass / (answer_pass + answer_fail) if (answer_pass + answer_fail) else 0
    metrics["abstention_correct_rate"] = abstention_pass / (abstention_pass + abstention_fail) if (abstention_pass + abstention_fail) else 0

    return {"metrics": metrics, "per_query": per_query, "n_queries": len(golden["queries"])}


def compare_to_baseline(metrics: dict) -> tuple[bool, list[str]]:
    if not BASELINES.exists():
        return True, ["No baseline exists yet. Run with --update-baseline to create one."]
    baseline = json.loads(BASELINES.read_text())["metrics"]
    failures = []
    for k, tolerance in REGRESSION_TOLERANCE.items():
        if k in metrics and k in baseline:
            if metrics[k] < baseline[k] - tolerance:
                failures.append(f"{k}: {metrics[k]:.3f} < baseline {baseline[k]:.3f} (tolerance {tolerance})")
    return len(failures) == 0, failures


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--rag-callable", required=True,
                        help="Importable 'module.path:function' that takes a question and returns a response dict")
    parser.add_argument("--update-baseline", action="store_true",
                        help="Save current results as the new baseline (use after intentional improvements)")
    args = parser.parse_args()

    rag = load_callable(args.rag_callable)
    result = run(rag, GOLDEN)

    REPORTS.mkdir(exist_ok=True)
    timestamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    report_path = REPORTS / f"run-{timestamp}.json"
    report_path.write_text(json.dumps(result, indent=2))
    print(f"Report saved: {report_path}")
    print(f"\nMetrics: {json.dumps(result['metrics'], indent=2)}")

    if args.update_baseline:
        BASELINES.write_text(json.dumps({"metrics": result["metrics"], "updated_at": timestamp}, indent=2))
        print(f"Baseline updated.")
        sys.exit(0)

    passed, failures = compare_to_baseline(result["metrics"])
    if not passed:
        print("\n❌ Regression detected:")
        for f in failures:
            print(f"  - {f}")
        sys.exit(1)
    print("\n✅ No regression.")


if __name__ == "__main__":
    main()
```

### `evals/judges.py`

LLM-as-judge stub with calibration warnings:

```python
"""
LLM-as-judge for faithfulness and citation quality.

⚠️  Do NOT use as the primary signal until calibrated against human labels.
    Uncalibrated judges have position, verbosity, self-preference, and style biases.

Recommended workflow:
1. Hand-grade 50 responses.
2. Run the judge on the same 50.
3. Compute agreement (Cohen's kappa or % agreement).
4. If agreement < 80%, refine the judge prompt and repeat.
5. Re-calibrate weekly in production.
"""
# Intentionally left as stubs — implement when you reach v2 evaluation.

def faithfulness_judge(question: str, answer: str, context: str) -> dict:
    """TODO: implement with calibration against human labels."""
    raise NotImplementedError("Implement after v1 hand-labeled eval is working.")


def citation_quality_judge(claim: str, cited_chunk: str) -> dict:
    """
    For each cited claim, check whether the cited chunk actually contains the assertion.
    Citation presence != citation quality.
    """
    raise NotImplementedError("Implement after v1 hand-labeled eval is working.")
```

### `evals/baselines.json`

```json
{
  "metrics": {
    "recall@10": 0.0,
    "precision@10": 0.0,
    "mrr": 0.0,
    "ndcg@10": 0.0,
    "answer_contains_rate": 0.0,
    "abstention_correct_rate": 0.0
  },
  "updated_at": "set-by-first-run"
}
```

### `evals/README.md`

```markdown
# RAG Evaluation

## Quickstart

1. Edit `golden_set.yaml` — replace the 10 placeholder queries with real ones from your domain. Target 50+ before tuning the system.

2. Implement a RAG callable that takes a question and returns:
   ```python
   {
     "answer": "...",
     "retrieved_doc_ids": ["doc-1", "doc-2"],
     "abstained": False,
   }
   ```

3. Run the eval:
   ```bash
   python -m evals.run_eval --rag-callable yourapp.rag:answer
   ```

4. After your first successful run, save a baseline:
   ```bash
   python -m evals.run_eval --rag-callable yourapp.rag:answer --update-baseline
   ```

5. Wire into CI — any PR that regresses beyond `REGRESSION_TOLERANCE` will fail.

## What to evaluate (v1 vs v2)

- v1: retrieval metrics (Recall@K, NDCG, MRR) + content checks (`expected_answer_contains`) + abstention correctness
- v2: LLM-as-judge for faithfulness and citation quality, calibrated against human labels

Do not start with LLM-as-judge. See `judges.py` for the calibration workflow.

## Coverage target

- 60% happy path
- 20% edge cases (multi-hop, comparison, rare terms)
- 20% known unanswerable (verify abstention)

## CI integration

GitHub Actions:
```yaml
- name: RAG eval gate
  run: python -m evals.run_eval --rag-callable yourapp.rag:answer
```
The runner exits 1 on regression beyond tolerance.
```

## Phase 4: Confirm and finish

After creating the files:

1. Tell the user what's in each file.
2. Point them at `golden_set.yaml` as the first thing to edit.
3. Suggest implementing the RAG callable signature in their existing pipeline.
4. Remind them: 50 labeled queries is the minimum before tuning.

## Style notes

- Create real, runnable code — not pseudocode placeholders.
- Stack-agnostic where possible; Python because the user said FastAPI + ADK.
- Mark v2 features (judges) as explicit `NotImplementedError` so they're not accidentally relied on.
