# Golden Dataset Structure

> The golden dataset is the source of truth. **NEVER modify cases to make tests pass.**

## 8-Folder Structure

```
tests/golden/
├── agents/                    # Per-agent golden eval cases
│   ├── retrieval_agent/
│   │   ├── golden.evalset.json    # ADK eval cases (adk eval format)
│   │   ├── critical_cases.evalset.json  # critical-path cases (100% threshold)
│   │   ├── dataset_manifest.yaml
│   │   └── deepeval_cases.json    # DeepEval test cases
│   ├── answer_agent/
│   │   ├── golden.evalset.json
│   │   └── dataset_manifest.yaml
│   └── <agent_name>/              # One folder per implemented agent
│       ├── golden.evalset.json
│       └── dataset_manifest.yaml
├── rag/                       # RAG faithfulness + precision cases
│   ├── qa_agent_cases.json
│   ├── retrieval_agent_rag.json
│   └── dataset_manifest.yaml
├── security/                  # CI BLOCKERS #1-#9 test cases
│   ├── tenant_isolation.json      # CI BLOCKER #1
│   ├── prompt_injection.json      # CI BLOCKER #2
│   ├── policy_bypass.json         # CI BLOCKER #3
│   ├── mcp_cross_tenant.json      # CI BLOCKER #4
│   ├── mcp_unauthorized.json      # CI BLOCKER #5
│   ├── rag_cross_tenant.json      # CI BLOCKER #6
│   └── dataset_manifest.yaml
├── policy/                    # Policy compliance cases (adapt to your domain)
│   ├── restricted_criteria_detection.json
│   ├── review_flag_cases.json
│   └── dataset_manifest.yaml
├── mcp/                       # MCP contract + schema + auth cases
│   ├── tool_surface_lock.json
│   ├── schema_strictness.json
│   ├── auth_cases.json
│   └── dataset_manifest.yaml
├── multi-turn/                # ADK User Simulation scenarios
│   ├── onboarding_flows.json
│   ├── scheduling_flows.json
│   └── dataset_manifest.yaml
├── regression/                # Cases that caught past bugs
│   └── dataset_manifest.yaml
└── integration/               # End-to-end multi-service cases
    └── dataset_manifest.yaml
```

## dataset_manifest.yaml Schema

```yaml
# tests/golden/agents/retrieval_agent/dataset_manifest.yaml
version: "1.0"
created: "2026-04-28"
agent: "retrieval_agent"
description: "Golden eval cases for retrieval_agent"

stats:
  total_cases: 8           # must meet Day-1 minimum
  critical_cases: 2        # critical-path cases tracked separately

thresholds:
  overall: 0.85            # final_response_match_v2 >= 0.85
  critical: 1.0            # 100% — NEVER miss a critical case

files:
  - path: golden.evalset.json
    format: adk_eval
    cases: 8
  - path: critical_cases.evalset.json
    format: adk_eval
    cases: 2
    threshold_override: 1.0

review_policy:
  requires_pr_review: true
  approved_by: []           # must have named approver before merging
  last_reviewed: "2026-04-28"

tags:
  - retrieval
  - your-domain-tags
```

## Per-Agent Case Minimums

| Agent | Day-1 minimum | Full target | Notes |
|-------|-------------|------------|-------|
| Primary high-risk agent | ≥ 8 | ≥ 100 | ≥ 2 must be critical-path cases |
| Secondary agents | ≥ 8 | ≥ 20 | At least 1 multi-tenant isolation case |
| All other agents | 0 at Day-1 | ≥ 20 before agent PR merges | Must exist before agent goes to staging |
| Security suite | ≥ 1 each type | ≥ 5 each type | Covers CI blockers #1-#9 |
| RAG agents | 0 at Day-1 | ≥ 10 faithfulness cases | Any RAG QA or messaging agent |
| MCP contract | ≥ 1 per tool | ≥ 3 per tool | Must cover auth, schema, and tenant isolation |

## ADK Eval Case Format (golden.evalset.json)

```json
{
  "evals": [
    {
      "name": "critical_case_example",
      "description": "Critical-path case — must classify correctly",
      "query": {
        "content": "Your domain-specific critical input here"
      },
      "expected_tool_use": [
        {
          "tool_name": "your_primary_tool",
          "tool_input": {}
        },
        {
          "tool_name": "your_followup_tool",
          "tool_input": {}
        }
      ],
      "expected_final_response": {
        "content": "Expected classification or response",
        "match_type": "IN_ORDER"
      },
      "tags": ["r1", "critical"]
    }
  ]
}
```

## Hard Rules

- **NEVER modify golden cases to make tests pass** — fix the agent, not the dataset
- **PR review required** for every change to `tests/golden/` — `dataset_manifest.yaml` must have a named approver
- **Version-controlled** — golden datasets are Git artifacts, never ephemeral
- **`critical_cases.evalset.json`** is separate from `golden.evalset.json` — tracked independently, 100% threshold
- **Regression flywheel** — when a production incident finds an agent error, the failing case goes into `tests/golden/regression/` before the fix is merged
