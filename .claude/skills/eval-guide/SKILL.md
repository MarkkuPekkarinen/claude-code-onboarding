---
name: eval-guide
description: "Use when writing eval code, configuring eval infrastructure, creating golden datasets, setting up PromptRegistry, authoring CI eval gates, or working with any eval tool: DeepEval, Ragas, Giskard OSS v3, Promptfoo, Langfuse, Arize Phoenix, adk eval, ADK User Simulation, Vertex GenAI Eval. Covers per-agent accuracy thresholds, CI tier structure (R1-R4), MCP eval suites, golden dataset structure, and PromptRegistry architecture. Also covers pytest harness configuration (asyncio_mode, InMemoryRunner, parametrize-over-golden)."
allowed-tools: Bash, Read, Write, Edit
metadata:
  triggers: deepeval, ragas, giskard, promptfoo, langfuse, phoenix, PromptRegistry, golden dataset, evalset, eval-smoke, eval-adk, redteam, MCPUseMetric, Faithfulness, ToolCallAccuracy, HallucinationsV1, tests/golden, dataset_manifest, seed-prompts, R1 gate, R2 nightly, R3 pre-release, R4 canary, ci tier, eval threshold, ArenaGEval, GeminiModel judge, set_default_generator, promptfooconfig.yaml, Scenario, Suite, make eval-all-local, make redteam-promptfoo, make giskard-scan, make mcp-eval-all, make seed-prompts-local, eval-reviewer, per-agent threshold, golden case, asyncio_mode, InMemoryRunner, pytest-asyncio, dataset_manifest.yaml, diff_langfuse_prompts, emergency pack, prompt registry, prompt lifecycle
  related-skills: google-adk, adk-eval-guide, python-dev, adk-observability-guide
  domain: agentic-ai
  role: specialist
  scope: evaluation
  output-format: code
last-reviewed: "2026-04-28"
---

# Eval Guide

## Iron Law

**NEVER generate eval tool code from memory. ALWAYS query Context7 MCP for the official API before writing any eval code.** Every metric class name, constructor signature, and YAML provider ID must be verified against current official docs — these APIs change between minor versions.

**Prefer LangChain-free eval paths.** Ragas, Giskard, and Promptfoo all have LangChain-free paths — prefer them to reduce dependency surface and avoid version conflicts.

**Consistent LLM judge.** Best practice: use the same LLM provider as your main stack for LLM-as-judge to reduce vendor sprawl. For Gemini-based stacks: `GeminiModel("gemini-2.5-flash")` for DeepEval, `Generator(model="google/gemini-3.1-flash")` for Giskard, `google:gemini-2.5-pro` for Promptfoo.

**Dispatch `eval-reviewer` agent after writing any eval code** — same mandate as dispatching `adk-reviewer` after ADK agent code.

## Documentation Sources — Query Context7 BEFORE Writing Any Tool Code

| Tool | Context7 query | Fallback |
|------|---------------|---------|
| DeepEval | `deepeval` | https://docs.confident-ai.com/docs |
| Ragas | `ragas` | https://docs.ragas.io/en/latest |
| Giskard OSS v3 | `giskard` | https://docs.giskard.ai/en/latest |
| Promptfoo | `promptfoo` | https://www.promptfoo.dev/docs |
| Langfuse | `langfuse` | https://langfuse.com/docs |
| Arize Phoenix | `arize-phoenix` | https://docs.arize.com/phoenix |
| ADK Eval | `google-adk` (adk-docs MCP) | https://google.github.io/adk-docs/evaluate |
| Vertex GenAI Eval | `google-cloud-aiplatform` | https://cloud.google.com/vertex-ai/generative-ai/docs/evaluate |
| pytest-asyncio | `pytest-asyncio` | https://pytest-asyncio.readthedocs.io |

## Reference Files

| File | When to use |
|------|-------------|
| `reference/deepeval-patterns.md` | MCPUseMetric, GeminiModel, 15 confirmed metric classes, ArenaGEval A/B testing |
| `reference/ragas-patterns.md` | ToolCallAccuracy, Faithfulness, ContextPrecision — LangChain-free path only |
| `reference/promptfoo-patterns.md` | YAML config, `google:gemini-2.5-pro` provider, 70+ red-team plugins, MCP security suite |
| `reference/giskard-patterns.md` | v3 Scenario/Suite API, LiteLLM Gemini setup, FHA check, RAGET v2-only warning |
| `reference/langfuse-prompts.md` | PromptRegistry abstraction, prompt lifecycle, `.compile()`, emergency pack, drift detection |
| `reference/golden-dataset.md` | 8-folder structure, `dataset_manifest.yaml` schema, per-agent case minimums |
| `reference/ci-tiers.md` | R1-R4 tier config, pytest marks (@r1/@r2), path-routing rules, 9 CI blockers reference |
| `reference/per-agent-thresholds.md` | Per-agent accuracy thresholds for all 14 agents, habitability 100% sub-threshold |
| `reference/mcp-eval-patterns.md` | MCP contract suite, tenant isolation test pattern, audit-log verification |
| `reference/pytest-harness.md` | `asyncio_mode = "auto"`, conftest.py template, InMemoryRunner, parametrize-over-golden |
| `reference/failure-mode-taxonomy.md` | 6 failure modes with symptom → eval tool routing table; fix patterns per mode |

## Process — Before Writing Any Eval Code

1. Identify which tool(s) are needed
2. Query Context7 for that tool's current API — the reference files are starting points, NOT the final authority on API signatures
3. Read the relevant reference file for patterns and gotchas
4. Check `reference/per-agent-thresholds.md` for the target agent's required thresholds
5. Check `reference/golden-dataset.md` for dataset structure and minimum case counts
6. Mark every test with `@pytest.mark.r1` (PR gate) or `@pytest.mark.r2` (nightly) — never unmarked
7. After implementation: dispatch `eval-reviewer` agent

## Make Targets Quick Reference

| Target | What it runs | When to use |
|--------|-------------|-------------|
| `make eval-smoke` | Lint + types + 1-2 eval cases for changed agent + prompt schema check | Every PR (< 30s) |
| `make eval-adk` | `adk eval` against all `tests/golden/agents/*/golden.evalset.json` | Full ADK eval |
| `make eval-deepeval` | `uv run pytest -m eval -k deepeval` | DeepEval metric runs |
| `make eval-ragas` | `uv run pytest -m eval -k ragas` | RAG metric runs |
| `make redteam-promptfoo` | `npx promptfoo eval -c tests/eval/promptfoo/` | Red-team + regression |
| `make giskard-scan AGENT=<name>` | Targeted Giskard scan → `reports/giskard/<agent>.html` | Security scan |
| `make mcp-eval-all` | Contract + auth + behavior + security suites for MCP server | MCP eval |
| `make eval-all-local` | All of the above in sequence | Full local validation |
| `make seed-prompts-local` | Seeds prompts into local Langfuse with `label="development"` | Prompt registry setup |
| `make diff-prompts-staging` | Detects Git ↔ Langfuse prompt drift | Pre-release check |
| `make phoenix-experiment AGENT=<name>` | Phoenix `run_experiment()` against golden dataset | Trace replay eval |
| `make mcp-inspect` | Launches `@modelcontextprotocol/inspector` against local MCP | Interactive MCP debug |
| `make eval-multiturn AGENT=<name>` | ADK User Simulation multi-turn flows | Multi-turn eval |
| `make update-mcp-hashes` | Regenerates `mcp/.tool-surface-hashes.json` | After MCP tool changes |

## Golden Dataset Minimum Requirements (Day-1)

| Agent/Suite | Minimum cases | Location |
|-------------|-------------|---------|
| Primary agent (highest-risk) | ≥ 8 Day-1 → ≥ 100 full target | `tests/golden/agents/<agent>/` |
| Secondary agents | ≥ 8 Day-1 → ≥ 20 full target | `tests/golden/agents/<agent>/` |
| Security suite | ≥ 1 each: prompt_injection, tenant_isolation, policy_bypass | `tests/golden/security/` |
| All other agents | ≥ 20 before agent PR merges | `tests/golden/agents/<agent>/` |
| RAG agents | ≥ 10 faithfulness cases | `tests/golden/rag/` |
| MCP contract | ≥ 1 per tool | `tests/golden/mcp/` |

## Related Skills

- `adk-eval-guide` — ADK-native eval only (8 ADK criteria, evalset schema, user simulation)
- `google-adk` — ADK agent construction patterns
- `adk-observability-guide` — Phoenix OTel integration, span inspection
