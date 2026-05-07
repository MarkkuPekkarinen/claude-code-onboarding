# Autonomous Feedback Loop — CLAUDE.md Block

Copy the block below into your project's `CLAUDE.md`. This contract
tells Claude Code exactly how to run the fix-redeploy-retest loop and,
critically, when to STOP.

---

## MCP Tool Validation Loop (MANDATORY before raising any PR)

After unit tests, lint, and build pass, run this loop:

### Loop procedure

1. **Run orchestrator**: `bash tests/run_validation.sh`
2. Inspect exit code:
   - `0` (GREEN) → all scenarios passed → proceed to PR creation
   - `1` (RED) → scenario failures → go to step 3
   - `2` (COVERAGE GAP) → tools without scenarios → STOP, ask user before scaffolding
   - `3` (CONNECTION) → protocol/transport error → check Docker logs, fix, retry once; STOP if persists
   - `10/11/12` → infra failures → fix Docker config, retry once; STOP if persists
3. **On RED** — read `tests/validation_report.json`. For each failed scenario:
   a. Identify root cause: handler bug | schema mismatch | missing feature | wrong assertion
   b. Locate file:line of the cause (do NOT guess — grep the codebase)
   c. State the fix in one sentence before applying it
   d. Apply the fix to source code (NOT to scenarios.yaml)
4. **Re-run orchestrator** (step 1)
5. **Iteration cap = 5**. If iteration 5 still RED → STOP, write a summary to `tests/loop_failure.md` with:
   - Iteration count
   - Each fix attempted and why it failed
   - Remaining failures with file:line evidence
   - Recommended next step for the human
6. **Do NOT raise PR** if loop exits non-zero.

### Hard rules (violating these is a critical failure)

- **Never** edit `scenarios.yaml` to make tests pass. Scenarios are the spec.
  Exception: if the scenario is provably wrong (e.g., asserts on a renamed field), the commit message MUST start with `[scenario-update]` AND include a one-line justification.
- **Never** mark a scenario as `xfail` or skip it without explicit user approval in the conversation.
- **Never** weaken an assertion (e.g., changing `min_results: 5` to `min_results: 1`) without `[scenario-update]` tag.
- **Never** raise a PR while `tests/loop_failure.md` exists from the current run.
- **Never** claim "all tools work" without citing the validation report path and exit code.
- **Never** assume a flaky failure. If the same scenario passes once and fails once, it is broken — investigate.

### Determinism check

If a scenario fails on iteration N but the suspected fix is "retry will work":
1. Re-run the validator a SECOND time without code changes.
2. If second run passes → the scenario or the tool is flaky → fix the flakiness (cause, not symptom). Do NOT proceed.
3. If second run fails identically → real bug, proceed with fix.

### Reporting contract

After every loop run (green or red), write to chat:
```
Validation loop completed.
  Iterations: N / 5
  Final verdict: GREEN | RED | COVERAGE_GAP
  Tools tested: X
  Scenarios: P passed, F failed
  Report: tests/validation_report.json
```

Include file:line citations for any fix applied. False completions are
worse than honest delays — if uncertain, STOP and ask.
