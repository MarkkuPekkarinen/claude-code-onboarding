# Leverage Patterns

## Task Response Protocol

For every task:

```
1. UNDERSTAND: Restate the task. Flag ambiguity.
2. PLAN: 3-5 bullet approach before coding.
3. DECISIONS: List design choices and tradeoffs.
4. IMPLEMENT: Simplest correct solution.
5. VERIFY: Dead code, unused imports, unrelated changes, edge cases.
6. REPORT: What changed, what didn't, any concerns.
```

For small/obvious tasks, compress — but NEVER skip UNDERSTAND or VERIFY.

For non-trivial changes (architecture, multi-service, schema changes): use the `plan-mode-review` skill or `/plan-review` command, which extends this protocol with Phase 0 self-review, approval scope triage, and production readiness gates.

## Declarative Over Imperative

Prefer success criteria over step-by-step commands:

> "I understand the goal is [success state]. I'll work toward that. Correct?"

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

## Test-First

When implementing new features or new logic (per CLAUDE.md: "Always write tests"):

1. Write the test that defines success
2. Implement until the test passes
3. Show both

For trivial changes (renaming, config tweaks, one-line fixes): run existing tests, don't write new ones unless behavior changed.

Tests are your loop condition.

## Naive Then Optimize

1. Implement the obviously-correct naive version first
2. Verify correctness
3. Then optimize while preserving behavior

Correctness first. Performance second. Never skip step 1.

## Browser MCP in the Loop

When applicable, use a browser MCP for real-time validation. Verify against actual rendered output or live behavior, not just static code analysis.

## Adaptive Depth Levels

Not every task needs the same depth of planning, testing, or documentation. Calibrate effort to the actual problem.

| Depth | When to Use | What It Means |
|-------|-------------|---------------|
| **Minimal** | Single-file fix, clear requirement, trivial change | Write code, run existing tests, done |
| **Standard** | Multi-file change, some ambiguity, moderate complexity | Plan first, write tests, verify contracts |
| **Comprehensive** | Architecture change, high risk, cross-service impact | Full plan approval, ADR, integration tests, security review |

### Factors That Push Depth Up

- Request is vague or uses undefined terms → +1 level
- Change touches shared utilities or interfaces → +1 level
- Risk of data loss or security impact → jump to Comprehensive
- Multiple components or services affected → +1 level

### Factors That Keep Depth Low

- Human has given very specific, detailed instructions
- Change is isolated to one file with no shared contracts
- Existing tests already cover the area

**Default:** Start at Minimal. Escalate only when a factor above applies. Do not gold-plate simple requests.

## Large Task Management

When a task is too large for a single context window:

- Break into self-contained subtasks with clear inputs/outputs
- Complete and verify each subtask before moving to the next
- Summarize completed work at each boundary for context carry-forward
- If losing track of earlier decisions, say so and request a recap

## Error Recovery

When a task goes wrong mid-execution, follow this protocol instead of pushing forward or starting over silently.

### Partial Completion

If you completed steps 1-3 of a 5-step plan and step 4 fails:

```
STOPPED at: [step 4 — describe what failed]
Completed: [steps 1-3 — list what was done]
Options:
A) Retry step 4 with a different approach: [describe alternative]
B) Skip step 4 and continue with step 5 (with known gap)
C) Roll back steps 1-3 and start fresh
→ Which do you prefer?
```

Never silently skip a failed step and claim the task is done.

### Conflicting Requirements

If you discover a conflict between what was asked and what the codebase allows:

```
CONFLICT FOUND:
- Requested: [what human asked for]
- Constraint: [what the code/system requires — file:line evidence]
- Impact: [what breaks if we force it]
Options:
A) [Approach that honors the request, costs X]
B) [Approach that honors the constraint, delivers Y instead]
→ Which takes precedence?
```

### Missing Context

If you cannot complete a task because a file, API, or dependency is unavailable:

```
BLOCKED: Cannot proceed without [specific missing thing]
What I have: [list what is available]
What I need: [exactly what is missing and why]
Options:
A) Proceed with [assumption] — risk: [what breaks if wrong]
B) Stop here until [missing thing] is provided
```

### User Changes Direction Mid-Task

If the human redirects while a task is in progress:

1. Stop current work immediately
2. List what was completed (with file:line)
3. List what was NOT started yet
4. Confirm: should completed work be kept, modified, or reverted?
5. Only then start the new direction

### Error Severity Triage

Before deciding how to handle any error, classify it:

| Severity | Meaning | Response |
|----------|---------|---------|
| **Critical** | Task cannot continue at all | Stop, report fully, list recovery options |
| **High** | Current approach is blocked, need alternative | Stop current approach, propose alternative |
| **Medium** | Can continue with workaround, quality reduced | Proceed with workaround, flag the gap explicitly |
| **Low** | Minor issue, non-blocking | Note it, continue, mention at end |

Never classify an error as Low when it hides a real problem.

### Change Request Decision Tree

When a user requests a change to ongoing or completed work:

```
User requests change
    |
    +-- Affects in-progress work?
    |   Yes -> Stop. List done (file:line). List not-started. Ask: keep / modify / revert?
    |
    +-- Affects a completed file or feature?
    |   Low impact (isolated) -> Inform and proceed
    |   High impact (cascading) -> List all affected areas, get explicit confirmation
    |
    +-- Affects architecture or structure?
        RED: List all cascading effects. Require explicit approval before changing.
```

**Before any destructive change:** commit or note the current state first so the human can roll back.
