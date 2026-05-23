# Agent Failure Mode Taxonomy

> Use this when an agent is underperforming. Classify the failure type first,
> then route to the right eval tool. Skipping classification wastes eval cycles.

## The 6 Failure Modes

| Mode | Description | Signal |
|------|-------------|--------|
| **Instruction misunderstanding** | Agent misreads its own role or task scope | Consistently wrong tool selected; response addresses different task than asked |
| **Output format error** | Response structure doesn't match `output_schema` | JSON parse failures; missing required fields; wrong enum values |
| **Context loss** | Multi-turn conversation degrades mid-session | Correct early turns, wrong late turns; agent forgets constraints stated 3+ turns back |
| **Tool misuse** | Wrong tool called, wrong order, or unnecessary calls | High tool call count with low `ToolCallAccuracy`; calling MCP tools when FunctionTools suffice |
| **Constraint violation** | Business rule or tenant isolation breach | Any CI BLOCKER firing; required review flag not set on restricted input |
| **Edge case collapse** | Unusual input causes silent wrong output or exception | Low confidence scores on outlier inputs; habitability misclassification |

---

## Failure → Eval Tool Routing

### Instruction Misunderstanding

**Root cause:** System prompt is ambiguous, underspecified, or conflicting with few-shot examples.

**How to diagnose:**
```bash
make phoenix-experiment AGENT=<name>   # trace which instruction branch fired
make eval-adk                           # check FinalResponseMatchV2 on diverse golden cases
```

**Eval tools:**
- **Arize Phoenix** → inspect `llm.instruction` span attribute to see which prompt branch the model took
- **ADK eval** (`adk eval`) → `FinalResponseMatchV2` on `tests/golden/agents/<agent>/golden.evalset.json`
- **Giskard** → `Scenario` with adversarial instruction variants; catches systematic misreading

**Fix pattern:** Rewrite the instruction's ambiguous clause in your PromptRegistry → re-seed prompts locally → re-eval.

---

### Output Format Error

**Root cause:** `output_schema` Pydantic model doesn't match what the prompt instructs the model to produce, OR the model ignores the schema under certain inputs.

**How to diagnose:**
```bash
uv run pytest tests/evals/ -k "format" -m r1   # format-specific cases
make eval-deepeval                               # check GEval("schema compliance")
```

**Eval tools:**
- **DeepEval** → `GEval` with criterion `"Response is valid JSON matching the required schema"` — catches format drift faster than golden cases
- **ADK eval** → output schema validation is built-in; any `output_schema` mismatch surfaces as a failed case
- **pytest** → add a `@pytest.mark.r1` test that asserts `TriageOutput.model_validate(response.content)` for every agent with a Pydantic `output_schema`

**Fix pattern:** Add 2-3 few-shot examples in the system prompt showing the exact JSON structure → re-eval.

---

### Context Loss

**Root cause:** Long conversation history pushes early constraints out of the model's effective attention window.

**How to diagnose:**
```bash
make eval-multiturn AGENT=<name>   # ADK User Simulation multi-turn flows
```

**Eval tools:**
- **ADK User Simulation** (`InMemoryRunner` + `run_async` with multi-turn `Content` list) → tests specifically whether the agent degrades across turns
- **Arize Phoenix** → inspect token count per turn; spikes near the end of a long session signal attention pressure
- **DeepEval** `ConversationalGEval` → scores contextual consistency across turn N vs turn N-5

**Fix pattern:** Add a `# Context anchor:` block at the start of the agent's instruction that restates the 2-3 invariants that must survive the full session. ADK `DatabaseSessionService` keeps state server-side — verify it's in use (never `InMemorySessionService` in production).

---

### Tool Misuse

**Root cause:** System prompt doesn't specify when to use each tool, or tool descriptions overlap and confuse the model.

**How to diagnose:**
```bash
make eval-deepeval   # MCPUseMetric, ToolCallAccuracy
make mcp-eval-all    # MCP contract suite — catches wrong-tool calls at the MCP layer
```

**Eval tools:**
- **DeepEval** `MCPUseMetric` → checks tool name, input correctness, and call ordering
- **Ragas** `ToolCallAccuracy(strict_order=True)` → strict ordering required for agents with sequential tool dependencies (per `per-agent-thresholds.md`)
- **Promptfoo** → log actual tool call sequences in `vars:` and assert with `toolCalls` assertion

**Fix pattern:** Add a `## When to use each tool` section to the agent's PromptRegistry instruction. Each tool gets one sentence describing preconditions. Re-eval `MCPUseMetric` immediately after prompt change.

---

### Constraint Violation

**Root cause:** Business rules (FHA, tenant isolation, audit log requirement) not enforced at the prompt level or in tool pre-conditions.

**How to diagnose:**
```bash
make redteam-promptfoo              # 70+ red-team plugins including FHA and tenant isolation
make giskard-scan AGENT=<name>      # FHA check, prompt injection, OWASP adversarial suite
uv run pytest tests/golden/security/ -m r1   # 9 CI blockers
```

**Eval tools:**
- **Promptfoo** red-team → `policy` plugin with FHA ruleset; `pii` plugin; `harmful` plugin
- **Giskard** → `Scenario` with FHA-bypass adversarial prompts; `InjectionDetector`
- **pytest golden/security/** → mandatory for all 9 CI BLOCKER categories; must pass before any agent PR merges
- **MCP eval** (`make mcp-eval-all`) → cross-tenant input ID test catches tenant isolation violations at the MCP layer

**Fix pattern:** Add constraint enforcement in the tool pre-condition (not the prompt) for agents that handle sensitive criteria. Prompt-level rules are insufficient — enforce in the tool's fallback path.

---

### Edge Case Collapse

**Root cause:** Training distribution doesn't include the unusual input; the model falls back to a plausible-but-wrong answer with high confidence.

**How to diagnose:**
```bash
make eval-adk   # compare golden cases vs edge-case evalset
# Check: tests/golden/agents/triage_agent/critical_cases.evalset.json specifically
```

**Eval tools:**
- **ADK eval** → separate `critical_cases.evalset.json` with threshold override = 1.0 (see `per-agent-thresholds.md` habitability sub-threshold)
- **DeepEval** `ArenaGEval` → A/B compare old vs new prompt on the failing edge cases; isolates whether prompt or model is at fault
- **Ragas** `AgentGoalAccuracyWithReference` → catches cases where tool calls look right but the final answer is wrong for an unusual input

**Fix pattern:** Add the failing case to `tests/golden/agents/<agent>/golden.evalset.json` immediately — this is the golden dataset growth mechanism. Then add 1-2 few-shot examples in the system prompt that show the correct handling of that input class.

---

## Quick Routing Table

| Symptom observed | Failure mode | First tool to run |
|---|---|---|
| Wrong tool called | Tool misuse | `make eval-deepeval` (MCPUseMetric) |
| JSON parse error in response | Output format | `make eval-adk` + `GEval` schema check |
| Works in turn 1, wrong in turn 5+ | Context loss | `make eval-multiturn AGENT=<name>` |
| FHA keyword not flagged | Constraint violation | `make redteam-promptfoo` |
| Correct tool, wrong final answer | Instruction misunderstanding | `make phoenix-experiment AGENT=<name>` |
| Confident wrong answer on unusual input | Edge case collapse | Check `critical_cases.evalset.json` |
| Critical case misclassified | Edge case collapse (CRITICAL) | CI BLOCKER — fix before any merge |
