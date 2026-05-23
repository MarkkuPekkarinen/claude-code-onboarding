# DeepEval Patterns

> **Verify via Context7 (`deepeval`) before using.** These patterns reflect API state as of 2026-04-28.

## Install

```toml
# services/ai-shared/pyproject.toml
deepeval = ">=2.0.0"   # pin to latest stable after Context7 verification
```

## GeminiModel Judge

```python
from deepeval.models import GeminiModel

# Best practice: use the same LLM provider as your main stack for the judge
judge = GeminiModel("gemini-2.5-flash")
# Using a consistent provider reduces vendor sprawl and ensures evaluation alignment
```

## MCPUseMetric — Primary MCP Eval Metric

```python
from deepeval.models import GeminiModel
from deepeval.metrics import MCPUseMetric
from deepeval.test_case import LLMTestCase

# Evaluate that your agent correctly called the expected MCP tool
test_case = LLMTestCase(
    input="Water heater leaking in unit 4B",
    actual_output=agent_response,
    mcp_servers=["your-project-mcp"],              # MCP server(s) available to agent
    mcp_tools_called=["your_tool_name"]            # tools the agent actually called
)
metric = MCPUseMetric(model=GeminiModel("gemini-2.5-flash"))
# Verify metric constructor signature via Context7 before using
```

## 15 Confirmed Metric Classes

| Category | Metric class | Typical target agent(s) |
|----------|-------------|-------------------------------|
| RAG | `AnswerRelevancyMetric(threshold=0.8)` | QA agents, messaging agents, root cause agents |
| RAG | `ContextualPrecisionMetric(threshold=0.8)` | Retrieval agents, QA agents |
| RAG | `ContextualRelevancyMetric(threshold=0.6)` | Retrieval agents, QA agents |
| RAG | `ContextualRecallMetric(...)` | QA agents (citation attribution) |
| RAG | `FaithfulnessMetric(threshold=0.9)` | Messaging agents (zero hallucinations gate) |
| Multi-turn | `TurnRelevancyMetric()` | Scheduling agents, onboarding agents |
| Multi-turn | `TurnFaithfulnessMetric()` | Messaging agents multi-turn flows |
| Multi-turn | `KnowledgeRetentionMetric()` | Onboarding agents |
| Agent | `TaskCompletionMetric()` | All conversational agents |
| Agent | `StepEfficiencyMetric()` | Retrieval agents, triage agents (redundant tool-call detection) |
| **MCP** | **`MCPUseMetric(model=GeminiModel(...))`** | **Every MCP-backed agent trajectory** |
| A/B compare | `ArenaGEval(name, criteria, evaluation_params)` | Prompt version A/B before Langfuse promotion |
| LLM-as-judge | `GEval(name, criteria, evaluation_steps)` | Custom rubrics (professionalism, role compliance) |
| Safety | `BiasMetric(model=GeminiModel(...))` | Messaging agents, assessment agents |
| Safety | `ToxicityMetric(model=GeminiModel(...))` | Messaging agents, onboarding agents |

> **Verify all class names via Context7 before writing code.** Class names change between DeepEval major versions.

## Pytest Integration

```python
import pytest
from deepeval import assert_test
from deepeval.models import GeminiModel
from deepeval.metrics import FaithfulnessMetric, MCPUseMetric
from deepeval.test_case import LLMTestCase

@pytest.mark.r1   # critical — runs on every PR
@pytest.mark.eval
def test_answer_agent_no_hallucinations(answer_agent_response):
    test_case = LLMTestCase(
        input="What does my document say about X?",
        actual_output=answer_agent_response.text,
        retrieval_context=answer_agent_response.retrieved_chunks
    )
    assert_test(test_case, [FaithfulnessMetric(
        threshold=0.9,
        model=GeminiModel("gemini-2.5-flash")
    )])
```

## ArenaGEval — Prompt A/B Testing

```python
from deepeval.metrics import ArenaGEval
from deepeval.test_case import LLMTestCase

# Compare prompt version A vs B before promoting in Langfuse
arena = ArenaGEval(
    name="triage-prompt-ab",
    criteria="Which response more accurately classifies urgency and explains the rationale?",
    evaluation_params=["input", "actual_output"]
)
# Verify ArenaGEval constructor via Context7 before using
```

## Known Gotchas

| Gotcha | Fix |
|--------|-----|
| `MCPUseMetric` requires actual MCP tool call in `mcp_tools_called` | Mock MCP server in unit tests; use real MCP in integration tests marked `@r2` |
| `FaithfulnessMetric` needs `retrieval_context` populated | Always pass the actual retrieved chunks from the agent run, not None |
| `GeminiModel` needs `GOOGLE_API_KEY` or Vertex auth | Use ADC in CI (Workload Identity); never hardcode keys |
| DeepEval async tests require `asyncio_mode = "auto"` in pytest config | See `reference/pytest-harness.md` |
