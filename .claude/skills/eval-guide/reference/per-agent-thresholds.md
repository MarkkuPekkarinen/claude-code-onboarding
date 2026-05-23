# Per-Agent Accuracy Thresholds

> These thresholds **block merge** if not met. Do NOT widen thresholds to pass tests.
> Replace example agent names with your project's actual agent names.

## Example Agent Threshold Table

The table below shows common threshold patterns. Adapt agent names and thresholds to your project.

| Agent | Trajectory threshold | Final-response threshold | RAG metric | Security/other |
|-------|---------------------|------------------------|-----------|----------------|
| `triage_agent` | `tool_trajectory_avg_score ≥ 0.7` | `final_response_match_v2 ≥ 0.85` (≥ 100 cases) | n/a | Latency P99 < 500ms; `ToolCallAccuracy(strict_order=True)` ≥ 0.9 (Ragas) |
| `retrieval_agent` | `tool_trajectory_avg_score ≥ 0.7` | top-1 match ≥ 0.9 | recall@10 ≥ 0.85; `ContextPrecision` (Ragas); `ToolCallAccuracy(strict_order=True)` ≥ 0.9 | Multi-tenant rule isolation = 100%; `AgentGoalAccuracyWithReference` (Ragas) |
| `pipeline_agent` | `final_response_match_v2 ≥ 0.8` per stage | n/a | n/a | n/a |
| `answer_agent` | n/a | `HallucinationsV1 = 0` | `Faithfulness` ≥ 0.9 (Ragas) | Bias score ≤ threshold (DeepEval) |
| `dashboard_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | Tenant isolation canary = 0 leaks; `TopicAdherence(mode="precision")` (Ragas) |
| `vision_agent` | n/a | confidence calibration ≥ 0.8 | n/a | n/a |
| `assessment_agent` | severity classification ≥ 0.85 | — | n/a | Policy-neutral language eval |
| `verification_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | Field accuracy ≥ 0.9 |
| `qa_agent` | n/a | `HallucinationsV1 = 0`; `groundedness_score ≥ 0.7` | `Faithfulness` ≥ 0.9 + `ContextPrecision` ≥ 0.8 (Ragas); `FactualCorrectness(mode="f1")` ≥ 0.85; per-slice recall@5 by query type | Citation attribution required; citation validator = 0 hallucinated chunk_ids per run |
| `scope_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | False-positive rate ≤ 0.1 |
| `root_cause_agent` | `final_response_match_v2 ≥ 0.8` | — | recall@5 on similar items | n/a |
| `ingestion_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | Idempotency = 100%; chunk dedup |
| `onboarding_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | Policy detector firing rate = 100% on adversarial test set |
| `scheduling_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | Conflict resolution correctness ≥ 0.9; `AgentGoalAccuracyWithoutReference` (Ragas) |
| `summary_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | n/a |

## Critical-Path Zero-Tolerance Sub-Threshold

For your highest-risk agent, the overall ≥ 85% threshold is **insufficient** for critical-path cases.
Define critical cases specific to your domain (e.g., safety-critical classifications, irreversible actions).

**Sub-threshold: 100%** — zero misclassified critical-path cases are acceptable.

A single miss on a critical-risk input is a **blocking CI failure** regardless of the overall aggregate score.

Tracked separately in: `tests/golden/agents/<agent>/critical_cases.evalset.json`
CI gate runs this file independently with threshold override = 1.0 in `dataset_manifest.yaml`.

## Threshold Reconciliation

If your strategy doc has conflicting thresholds in different sections, the recommended resolution:
**overall threshold + 100% critical sub-threshold** (e.g., 85% overall + 100% on critical cases).

## Other Hard Zero-Tolerance Gates

| Agent | Metric | Threshold |
|-------|--------|-----------|
| Answer / messaging agents | `HallucinationsV1` | **0** — any hallucination = block |
| RAG QA agents | `HallucinationsV1` | **0** — any hallucination = block |
| Policy-gated agents | Policy detector firing rate | **100%** on adversarial set |
| Any multi-tenant agent | Tenant isolation canary | **0 leaks** — page on any violation |
| Any agent | Tenant isolation (cross-tenant data) | **0** — CI BLOCKER #1 |

## Default Threshold for Unlisted Agents

All agents not in the table above: `final_response_match_v2 ≥ 0.80`
Source: `eval-tooling-strategy.md` — "all others ≥ 80% FinalResponseMatchV2"

---

## Production Rollback Triggers

These thresholds apply **after** an agent is deployed to staging or production.
Monitored via Phoenix + Prometheus dashboards (`make phoenix-experiment` for replay, Grafana for live).

If ANY trigger fires → immediately revert to the previous stable PromptRegistry version
(`diff-prompts-staging` shows the delta; Langfuse preserves all prior versions by label).

| Metric | Rollback threshold | How measured |
|--------|-------------------|-------------|
| Task success rate | Drops > 10% from 7-day baseline | Phoenix `session.success_rate` aggregation |
| Critical-path case misclassification | Any single miss | `critical_cases` canary — always-on R4 gate |
| Tenant isolation violation | Any single leak | Multi-tenant agent canary — pages on-call immediately |
| Policy detector miss | Any single miss on known adversarial input | Promptfoo canary — re-runs red-team suite on deploy |
| Tool call error rate | Increases > 5% from baseline | Phoenix `tool.error_rate` span attribute |
| P99 response latency | Increases > 30% from baseline | Prometheus `adk_request_duration_p99` |
| Cost per task (token usage) | Increases > 20% from baseline | Phoenix token count aggregation per session |
| `HallucinationsV1` count | Any non-zero for answer/messaging agents | DeepEval metric run in R4 canary |

### Rollback Process

```
1. Trigger detected (Grafana alert OR on-call page)
2. Run: make diff-prompts-staging → identify changed prompt(s)
3. In Langfuse: revert affected prompt(s) to prior label ("production" → previous version)
4. Run: make seed-prompts-local → verify local stack matches reverted state
5. Run: make eval-smoke → confirm no immediate regression
6. File a follow-up issue with: trigger observed, metric value, prompt diff, reproduction steps
7. Do NOT re-deploy the failed version without a new eval cycle + eval-reviewer approval
```

### Monitoring Setup

- **Grafana dashboard:** Create a per-project agents dashboard — tracks all 8 metrics above per agent
- **Alerting:** PagerDuty integration via Prometheus `AlertManager` — pages on-call for critical-path and tenant isolation triggers only; others are Slack-only alerts
- **Canary traffic:** Cloud Run traffic splitting — new prompt versions receive 10% traffic for 24h before full rollout (configured in your infrastructure)
