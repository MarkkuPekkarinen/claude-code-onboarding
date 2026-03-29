# First Principles — Session Invariants

This file is the **numeric enforcement layer** on top of `core-behaviors.md`.
Where core-behaviors gives guidance, this file gives measurable pass/fail gates.

**Precedence:** This file sits between `core-behaviors` and `code-standards`.
When a rule here conflicts with `code-standards`, this file wins.

---

## Layer 1 — Hard Constraints

These are absolute. No exceptions, no judgment calls. Violation = stop immediately and report.

### Data Safety
- `DROP`, `DELETE`, `TRUNCATE` on any table → **STOP. Get explicit approval first.**
- Modifying a production database directly → **STOP. Migrations only.**
- Committing `.env`, `*.pem`, `*.key`, `credentials.*` → **STOP. Use environment variables.**

### Code Safety
- Pushing directly to `main` or `develop` → **STOP. PR only.**
- Skipping tests to ship faster → **STOP. Tests are not optional.**
- Using `as any` in NEW TypeScript code → **STOP. Add a proper type.**
- `console.log` / `console.warn` / `console.error` in new production TypeScript → **STOP. Use Logger.**
- `print()` in new Python production code → **STOP. Use structured logger.**

### Scope Safety
- Touching files outside the stated task → **STOP. Ask first.**
- Refactoring adjacent code while fixing a bug → **STOP. Separate PR.**
- Deleting pre-existing code you don't fully understand → **STOP. Ask first.**

---

## Layer 2 — Quality Thresholds

Numeric gates. Binary pass/fail. No "mostly" or "almost".

### Test Coverage (per session)
| What changed | Required |
|---|---|
| New feature or new logic | ≥ 1 test for happy path + ≥ 1 test for primary error path |
| Bug fix | ≥ 1 test that reproduces the bug before the fix |
| Refactor | All existing tests pass before AND after — no new tests required |
| Config / rename / trivial | Existing tests pass — no new tests required |

**Measurement:** Run the test suite. Show pass/fail count. "Looks right" is not evidence.

### Type Safety (TypeScript — NestJS + Angular)
| Metric | Threshold | How to check |
|---|---|---|
| New `as any` introduced | **0** | `grep -c "as any" <changed files>` |
| New `: any` parameters | **0** | `grep -c ": any\b" <changed files>` |
| `eslint-disable` added | **0** (unless justified in PR comment) | `grep -c "eslint-disable" <changed files>` |

### Type Safety (Dart — Flutter)
| Metric | Threshold | How to check |
|---|---|---|
| New `dynamic` without justification | **0** | `grep -c "\bdynamic\b" <changed dart files>` |
| Flutter analyzer errors | **0** | `flutter analyze` exit code = 0 |
| Flutter analyzer warnings introduced | **0 new** | Compare warning count before/after |

### Error Handling
| Metric | Threshold | How to check |
|---|---|---|
| Bare `catch(e) {}` (swallowed) | **0** | `grep -c "catch.*{[[:space:]]*}" <changed files>` |
| `catch` without log + rethrow/error-state | **0** | Review every new catch block |
| Python bare `except:` | **0** | `grep -c "except:" <changed py files>` |

### Commit Discipline
| Metric | Threshold |
|---|---|
| Files changed in one commit | ≤ 15 (larger = split first) |
| Unrelated files in same commit | 0 |
| TODO / FIXME in new code | 0 (either do it or create a task) |

### Security (when changed files touch auth, crypto, input handling, file uploads)
| Gate | Threshold |
|---|---|
| `security-reviewer` agent verdict | No CRITICAL or HIGH unresolved |
| Passwords stored/compared as plaintext | 0 |
| SQL built via string concatenation | 0 |
| User input used without validation | 0 |

---

## Layer 3 — Workflow Invariants

Sequencing rules. These define what must happen before/after key actions.

```
Before writing code:
  → Assumptions surfaced (core-behaviors §1)
  → MCP consulted for the relevant framework (code-standards.md)

Before opening a PR:
  → /ship gate passed (all items green)
  → Change description written (CHANGES MADE / DIDN'T TOUCH / CONCERNS)

Before any architecture change:
  → ADR created first, code second
  → /design-architecture or @architect used

After any correction by the user:
  → Lesson written to lessons.md BEFORE continuing work

After any session with code changes:
  → Blackbox entry appended (stop-blackbox-log.sh handles this)

After any refactor:
  → Dead code created by YOUR changes removed immediately
  → Pre-existing dead code: list it, ask before removing
```

---

## Layer 4 — AI Anti-Pattern Detection

Named, detectable failure modes specific to LLMs. Flag these in self-review before reporting done.

### Hallucinated API
**What:** Code uses a method, parameter, or class that doesn't exist in current docs.
**Detection:** Does every API call have MCP-verified evidence from this session?
**Fix:** Query MCP for the method signature. If it doesn't exist, find the real one.

### Stale Context Drift
**What:** A decision made in this conversation is contradicted by new code without acknowledgment.
**Detection:** Does this code conflict with any ASSUMPTION I stated earlier this session?
**Fix:** Acknowledge the conflict explicitly. Ask which takes precedence.

### Confidence Without Evidence
**What:** Claiming something "works" or is "implemented" without running it or reading the code.
**Detection:** Is this claim backed by a test run output or a file:line reference?
**Fix:** Run the test. Read the file. Then claim.

### Sycophancy Drift
**What:** Changing a position after user pushback without re-verifying — just agreeing to avoid conflict.
**Detection:** Did I change my answer? If yes — did I re-read the file first?
**Fix:** Re-verify with file:line evidence. If still correct, restate with proof. If wrong, say so explicitly.

### Premature Abstraction
**What:** Creating an interface, base class, factory, or plugin architecture for a single use case.
**Detection:** Does this abstract thing have fewer than 3 concrete implementations TODAY?
**Fix:** Inline it. Abstraction is justified at 3+ uses (Rule of Three, code-standards.md).

### Scope Creep Masquerading as Helpfulness
**What:** "While I was in there, I also cleaned up..." — touching code outside the task.
**Detection:** Does every changed line trace directly to the user's stated request?
**Fix:** Revert the extra changes. Open a separate task for cleanup.

### Over-Apology Pattern
**What:** Starting corrections with "I apologize, I'm sorry, I made a mistake..." before every fix.
**Detection:** Does the response lead with an apology rather than the correction?
**Fix:** Skip the apology. State what was wrong. Give the fix. Move on.

---

## Self-Check Before Reporting Done

Run this before saying any task is complete:

```
Layer 1 — Hard Constraints:
  □ No data safety violations
  □ No code safety violations (no new `as any`, no console.log, no direct push)
  □ No scope safety violations

Layer 2 — Quality Thresholds:
  □ Tests: correct tier for what changed (feature/bugfix/refactor/trivial)
  □ Type safety: zero new `as any` or `dynamic` in changed files
  □ Error handling: zero bare catch blocks in changed files
  □ Commit size: ≤ 15 files, no unrelated files, no TODOs

Layer 3 — Workflow Invariants:
  □ Correct workflow step completed for this action type

Layer 4 — Anti-Patterns:
  □ No hallucinated APIs (MCP verified)
  □ No confidence without evidence
  □ No scope creep
```

**If ANY box is unchecked → do not say "done". Fix it first or state it explicitly as a known gap.**
