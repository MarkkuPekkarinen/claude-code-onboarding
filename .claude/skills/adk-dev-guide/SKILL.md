---
name: adk-dev-guide
description: "ADK development lifecycle guardrails — 4-phase workflow (Understand → Build → Evaluate → Deploy), import precision rules, GOOGLE_CLOUD_LOCATION debugging, code preservation, and infinite loop breaking. Load BEFORE google-adk when starting a new ADK agent feature."
allowed-tools: Bash, Read, Write, Edit
metadata:
  triggers: adk dev, adk lifecycle, adk workflow, new adk agent, adk debugging, adk import, GOOGLE_CLOUD_LOCATION
  related-skills: google-adk, adk-eval-guide, adk-deploy-guide
  domain: agentic-ai
  role: specialist
  scope: workflow
  output-format: guide
last-reviewed: "2026-04-16"
---

# ADK Development Guide

Development lifecycle guardrails for AI agents using Google ADK and Gemini models.

## 4-Phase Development Lifecycle

Every ADK agent feature follows this workflow. Skipping phases increases risk of eval failures, infinite loops, and deployment issues.

### Phase 1: Understand Spec
**Before writing any code:**
- Read `DESIGN_SPEC.md` completely — this is the source of truth
- Identify: agent purpose, required tools, safety constraints, success criteria, edge cases
- Flag ambiguities, contradictions, or missing information before proceeding
- Check if similar agent patterns exist in your project already (avoid duplication)
- Clarify: is this a new agent or an enhancement to an existing one?

**Stop if:**
- The spec is vague or self-contradictory
- Required dependencies are unavailable
- The scope exceeds what a single agent should handle

### Phase 2: Build
**Follow these patterns:**
- Use `ToolContext` for session state — never global variables
- Import tools with precision (see ADK Import Precision Rules section below)
- Add `# Fallback:` comment to every tool function
- Use `InMemoryRunner` for development and tests
- Development commands:
  - `adk web` — launch ADK playground for interactive testing
  - `uv run pytest tests/ -v` — run unit tests
  - `uv run ruff check src/ && uv run ruff format src/` — lint and format
  - `uv run mypy src/` — type check

**Stop if:**
- Type errors appear when running `mypy`
- Linting fails (`ruff check` returns non-zero)
- Unit tests fail

### Phase 3: Evaluate
**Iterate 5–10 rounds per feature:**
- Create `evalset.json` with: 1 happy path, 1 error path, 1+ edge cases
- Create `eval_config.json` with appropriate eval criteria
- Run: `adk eval ./app evalset.json --config_file_path=eval_config.json --print_detailed_results`
- Review detailed results — identify failure patterns
- Refine agent instructions, tool signatures, or tool implementations
- Re-run until success rate stabilizes
- Common pitfalls: app name must match directory name, state type mismatches, tool return types

**Stop if:**
- Success rate plateaus below target threshold (defined in eval_config.json)
- Same test case fails repeatedly for unrelated reasons

### Phase 4: Deploy
**Use adk-deploy-guide skill:**
- Choose between Cloud Run (event-driven, full control) or Agent Engine (managed)
- Verify health endpoint responds after deployment
- Run `uv run pytest tests/evals/` locally before opening PR
- Eval gates block merge if accuracy thresholds are not met

---

## DESIGN_SPEC.md as Primary Source of Truth

Every ADK agent project MUST have a `DESIGN_SPEC.md` in the agent service root before any implementation code is written.

### Spec Contents (Required Sections)

```
# Agent Name — Design Spec

## Purpose
One-sentence mission statement.

## Example Use Cases
- User does X, agent responds with Y
- User does A, agent handles error B gracefully

## Required Tools
- tool_name: description and responsibility
- tool_name: description and responsibility

## Safety Constraints
- No [X] without [Y]
- Always [Z] before [A]
- Blocked: [B] under any condition

## Success Criteria
- Agent achieves 90% accuracy on test set
- Tool calls execute in <500ms
- Error recovery succeeds in <1 min

## Edge Cases & Fallbacks
- When tool A fails: [fallback behavior]
- When state is invalid: [reset or error response]
```

### Implementation ↔ Spec Alignment
- Implementation must align with spec — drift = stop and reconcile
- If implementation requires spec change: update spec first, then code
- If spec is impossible to implement: surface this during Phase 1 (Understand), not Phase 2 (Build)

---

## ADK Import Precision Rules

ADK tools must be imported from their **specific submodule**, not from the package level.

### Correct Import Patterns

```python
# ✅ CORRECT — import from specific submodule
from google.adk.tools.google_search import google_search
from google.adk.tools.load_web_page import load_web_page
from google.adk.tools.built_in_code_execution import built_in_code_execution

# ❌ WRONG — DO NOT import from package level
from google.adk.tools import google_search       # ✗ Will fail at runtime
from google.adk.tools import load_web_page       # ✗ Will fail at runtime
```

### Commonly Used Built-In Tools (Correct Import Paths)

| Tool | Correct Import |
|------|----------------|
| Google Search | `from google.adk.tools.google_search import google_search` |
| Load Web Page | `from google.adk.tools.load_web_page import load_web_page` |
| Built-In Code Execution | `from google.adk.tools.built_in_code_execution import built_in_code_execution` |

**Rule:** When in doubt about import syntax, check the google-adk skill or the official ADK documentation — do not guess.

---

## GOOGLE_CLOUD_LOCATION Debugging

Model 404 errors are almost always a location issue, not a model name issue.

### Debug Sequence

1. **Check GOOGLE_CLOUD_LOCATION env var** — must be set to a region that supports the model
   - Verify region supports the model in Google's documentation before assuming

2. **Check GOOGLE_CLOUD_PROJECT env var** — must be set to a valid GCP project ID

3. **Only then check model name** — but rarely the issue if steps 1–2 are correct

### Example Error & Recovery

```
Error: 404 Model 'projects/my-project/locations/europe-west1/models/gemini-3.1-flash' not found

↓ Fix:
GOOGLE_CLOUD_LOCATION=us-central1 python app.py
```

**Remember:** Location is the #1 cause of 404 errors in ADK development. Check it first.

---

## Code Preservation Principle

Once an agent is working, protect it from accidental breakage.

### Never Do This Without Explicit Approval

- Change the model in existing agent code
- Rewrite working agent code (refactor incrementally instead)
- Remove tools from an agent
- Rename `output_key` values (downstream agents reference them by name)
- Modify tool signatures without updating all callers

### Safe Refactoring
- Extract duplicated logic into helper functions
- Rename variables for clarity
- Update comments and docstrings
- Add new tools without removing old ones
- Adjust agent instructions (careful — may change behavior)

---

## Breaking Infinite Loops

If the same error occurs 3+ times in a row: **STOP immediately**. Do not retry the same approach.

### Common ADK Infinite Loops

- Tool returns error → model retries same tool → same error (repeat forever)
- State validation fails → agent resets state → validation fails again
- Rate limit hit → agent retries immediately → rate limit hit again

### How to Break the Loop

1. **Add `on_tool_error_callback`** to interrupt the retry cycle
2. **Adjust agent instruction** to handle the specific error gracefully
3. **Add state guards** to detect invalid state before calling tools
4. **Implement exponential backoff** for rate-limited tools

### Escalation Protocol

After 3 identical failures:
```
STOPPED after 3 identical failures:
- Attempt 1: [what you tried, what failed]
- Attempt 2: [what you tried, what failed]
- Attempt 3: [what you tried, what failed]

Options:
A) Different approach: [describe]
B) Escalate to human — need more context
```

---

## Project-Specific Constraints

> Replace this section with your project's ADK constraints.
> Document: ADK version pin, model name(s), tool placement rules (R1/R2), eval thresholds,
> session backend choices, and any compliance requirements.

Example table:

| Constraint | Value | Notes |
|-----------|-------|-------|
| ADK version | `google-adk==X.Y.Z` exactly | Pin to specific version |
| Model | `gemini-3.1-flash` | Default — override per agent if needed |
| Runner (dev) | `InMemoryRunner` for tests | Never use real API in unit tests |
| Runner (prod) | `Runner` for production | Wire VertexAiSessionService |
| Every tool must have | `# Fallback:` comment | Defines degradation mode |
| Eval gates | Accuracy thresholds block merge | Define per-agent thresholds |

---

## Stale Skills Detection

Run periodically to detect outdated skill files:

```bash
# Check if skills are outdated (>90 days)
npx skills check -g

# Update all skills to latest version
npx skills update -g

# Update specific skill
npx skills update adk-dev-guide -g
```

If a skill's `last-reviewed` date is >90 days old, flag it for review before using.

---

## Testing Without Burning API Credits

When you need to validate system behavior, measure performance, or run CI without real LLM calls:

### Deterministic Shadow Agent

Create a variant of your ADK agent that overrides only the LLM decision callback with deterministic heuristics. Same tool contracts, same output schema, same session state — zero `model` calls.

```python
# Standard LLM-powered agent
class RunnerAgent(BaseAgent):
    async def _run_async_impl(self, ctx: InvocationContext):
        result = await self.llm.generate_content_async(build_prompt(ctx.session.state))
        # ... handle result

# Shadow: same class hierarchy, no LLM
class AutopilotRunnerAgent(RunnerAgent):
    async def _run_async_impl(self, ctx: InvocationContext):
        state = ctx.session.state
        decision = "slow" if state["energy"] < 0.3 else "steady"
        ctx.session.state["decision"] = decision
        yield Event(author=self.name, content=types.Content(parts=[types.Part(text=decision)]))
```

Switch via env var — no code-path changes at the call site:

```python
def get_runner_agent() -> BaseAgent:
    if os.getenv("RUNNER_MODE") == "autopilot":
        return AutopilotRunnerAgent()
    return RunnerAgent()
```

Use the autopilot variant in all `InMemoryRunner` unit tests. Zero API cost, deterministic assertions.

### NDJSON Replay for Integration Tests and Demos

Record every event your ADK agent emits to a `.ndjson` file during a real run. Replay against the frontend or test harness without running agents:

```python
# Record in agent's broadcast/after_agent layer
with open("recordings/sim-run.ndjson", "a") as f:
    f.write(json.dumps({"ts": elapsed, "event": event.model_dump()}) + "\n")
```

Commit the recording — it becomes a regression baseline. CI replays it; no agents need to be running.

**When to use either pattern:** CI integration tests, load testing (run 1000s of autopilot agents cheaply), keynote demos, UI development iterations.

> Full implementation detail for both patterns: `agentic-agent-variant-ladder.md` in `agentic-ai-dev/reference/`

## Reference Files

- **`adk-dev-lifecycle.md`** — Full detail on each phase, commands, common pitfalls
- **`google-adk/SKILL.md`** — Agent patterns, tool API reference, ToolContext usage
- **`adk-eval-guide` skill** — Evaluation strategy and eval dataset structure
- **`adk-deploy-guide` skill** — Deployment to Cloud Run / Agent Engine, health checks, rollback
- **`agentic-ai-dev/reference/agentic-agent-variant-ladder.md`** — Agent variant ladder, deterministic shadow agents, NDJSON replay

---

## Quick Reference: When to Load This Skill

Load **adk-dev-guide BEFORE google-adk** when:
- Starting a new ADK agent feature
- Debugging an infinite loop or eval failure
- Onboarding a new developer to ADK patterns
- Reviewing an ADK agent's lifecycle

Load **google-adk only** when:
- Writing agent code (patterns, APIs, ToolContext)
- Implementing a specific tool
- Tweaking agent instructions
