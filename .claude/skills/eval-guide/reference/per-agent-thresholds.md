# Per-Agent Accuracy Thresholds — PropertyHarbor

> Source: `docs/architecture/eval-tooling-strategy.md` lines 1505-1525.
> These thresholds **block merge** if not met. Do NOT widen thresholds to pass tests.

## All 15 Agents — Threshold Table

| Agent | Trajectory threshold | Final-response threshold | RAG metric | Security/other |
|-------|---------------------|------------------------|-----------|----------------|
| `triage_agent` | `tool_trajectory_avg_score ≥ 0.7` | `final_response_match_v2 ≥ 0.85` (≥ 100 cases) | n/a | Latency P99 < 500ms; `ToolCallAccuracy(strict_order=True)` ≥ 0.9 (Ragas) |
| `matching_engine` | `tool_trajectory_avg_score ≥ 0.7` | top-1 match ≥ 0.9 | recall@10 ≥ 0.85; `ContextPrecision` (Ragas); `ToolCallAccuracy(strict_order=True)` ≥ 0.9 | Multi-tenant rule isolation = 100%; `AgentGoalAccuracyWithReference` (Ragas) |
| `eta_service` | `final_response_match_v2 ≥ 0.8` per stage (4 stages) | n/a | n/a | n/a |
| `messaging_agent` | n/a | `HallucinationsV1 = 0` | `Faithfulness` ≥ 0.9 (Ragas) | Bias score ≤ threshold (DeepEval) |
| `portfolio_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | Tenant isolation canary = 0 leaks; `TopicAdherence(mode="precision")` (Ragas) |
| `vision_qa_agent` | n/a | confidence calibration ≥ 0.8 | n/a | n/a |
| `dispute_assessment_agent` | severity classification ≥ 0.85 | — | n/a | FHA-neutral language eval |
| `verification_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | OCR field accuracy ≥ 0.9 |
| `lease_qa_agent` | n/a | `HallucinationsV1 = 0`; **`groundedness_score ≥ 0.7`** (issue #520, env-routed via `GOOGLE_GENAI_USE_VERTEXAI`: local Gemini classifier / stage+prod Vertex `check-grounding`) | `Faithfulness` ≥ 0.9 + `ContextPrecision` ≥ 0.8 (Ragas); `FactualCorrectness(mode="f1")` ≥ 0.85; **per-slice recall@5** (issue #522 X4 — 7 floors: factual_lookup ≥ 0.85, exact_identifier ≥ 0.90, broad_semantic ≥ 0.75, policy_legal ≥ 0.85, vague_short ≥ 0.65, multi_part ≥ 0.70, temporal ≥ 0.75; enforced in `tests/eval/lease_qa/test_retrieval_quality.py`, ADR-018 / §51 for reranker contract) | Citation attribution required; **citation validator = 0 hallucinated chunk_ids per run** (issue #520) |
| `scope_drift_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | False-positive rate ≤ 0.1 |
| `root_cause_agent` | `final_response_match_v2 ≥ 0.8` | — | recall@5 on similar tickets | n/a |
| `lease_ingestion_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | Idempotency = 100%; chunk dedup |
| `landlord_onboarding_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | **FHA detector firing rate = 100% on adversarial test set** |
| `scheduling_agent` | `final_response_match_v2 ≥ 0.8` | — | n/a | Conflict resolution correctness ≥ 0.9; `AgentGoalAccuracyWithoutReference` (Ragas) |
| `harbor_brief_agent` | `final_response_match_v2 ≥ 0.8` (constraints §26 default — added by PH-EVAL-019 issue #297) | — | n/a | n/a |

## Habitability Zero-Tolerance Sub-Threshold

For `triage_agent`, the overall ≥ 85% threshold is **insufficient** for `risk_level: critical` cases:
- Flooded unit
- Gas leak
- No heat in winter
- Electrical hazard

These are **jurisdictionally defined habitability emergencies** under US landlord-tenant statutes.

**Sub-threshold: 100%** — zero misclassified habitability emergencies are acceptable.

A single missed Emergency on a critical-risk ticket is a **blocking CI failure** regardless of the
overall 85% aggregate score.

Tracked separately in: `tests/golden/agents/triage_agent/critical_cases.evalset.json`
CI gate runs this file independently with threshold override = 1.0 in `dataset_manifest.yaml`.

## Triage Threshold Reconciliation

The strategy doc notes a potential conflict between 95% (mentioned in some sections) and 85%
(the primary stated threshold). **Resolution: 85% overall + 100% critical habitability sub-threshold.**
This is the correct interpretation per `eval-tooling-strategy.md §11 item 1`.

## Other Hard Zero-Tolerance Gates (from §10 constraints)

| Agent | Metric | Threshold |
|-------|--------|-----------|
| `messaging_agent` | `HallucinationsV1` | **0** — any hallucination = block |
| `lease_qa_agent` | `HallucinationsV1` | **0** — any hallucination = block |
| `landlord_onboarding_agent` | FHA detector firing rate | **100%** on adversarial set |
| `portfolio_agent` | Tenant isolation canary | **0 leaks** — page on any violation |
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
| Habitability emergency misclassification | Any single miss | `critical_cases` canary — always-on R4 gate |
| Tenant isolation violation | Any single leak | `portfolio_agent` canary — pages on-call immediately |
| FHA detector miss | Any single miss on known adversarial input | Promptfoo canary — re-runs red-team suite on deploy |
| Tool call error rate | Increases > 5% from baseline | Phoenix `tool.error_rate` span attribute |
| P99 response latency | Increases > 30% from baseline | Prometheus `adk_request_duration_p99` |
| Cost per task (token usage) | Increases > 20% from baseline | Phoenix token count aggregation per session |
| `HallucinationsV1` count | Any non-zero for `messaging_agent` / `lease_qa_agent` | DeepEval metric run in R4 canary |

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

- **Grafana dashboard:** `ph-agents` dashboard — tracks all 8 metrics above per agent
- **Alerting:** PagerDuty integration via Prometheus `AlertManager` — pages on-call for habitability and tenant isolation triggers only; others are Slack-only alerts
- **Canary traffic:** Cloud Run traffic splitting — new prompt versions receive 10% traffic for 24h before full rollout (configured in `infra/terraform/cloud_run.tf`)
