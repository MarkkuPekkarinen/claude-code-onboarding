---
description: Run a 6-role PR review covering comment accuracy, test coverage, error handling, type design, code quality, and simplification. Dispatches specialized agents by concern — not by tech stack. Use before creating a PR or reviewing someone else's changes. Optional topic filter: comments, tests, errors, types, code, simplify (default: all 6 roles).
allowed-tools: Bash, Read, Glob, Grep, Task
disable-model-invocation: true
---

# PR Review — 6 Roles

Run a concern-specific review of code changes. Each role examines a different dimension regardless of tech stack.

## Roles

| Role | Agent | Focus |
|------|-------|-------|
| Comment accuracy | `comment-analyzer` | Comments vs actual code |
| Test coverage | `pr-test-analyzer` | Behavioral gaps, not line coverage |
| Error handling | `silent-failure-hunter` | Silent failures, swallowed exceptions |
| Type design | `type-design-analyzer` | Invariants, encapsulation, invalid states |
| Code quality | `code-reviewer` | Bugs, style, CLAUDE.md compliance |
| Simplification | `code-simplifier` | Unnecessary complexity |

## Process

1. **Determine scope** — From `$ARGUMENTS`; if not specified use `git diff HEAD~1`
2. **Determine roles** — Parse topic filter from `$ARGUMENTS` (see Topic Filters below); default: all 6
3. **Dispatch agents** — Run each selected agent against the scope; collect findings
4. **Aggregate** — Group all findings by severity across all roles

## Topic Filters

If `$ARGUMENTS` contains one of these words, run only that role:

| Filter word | Agent dispatched |
|-------------|-----------------|
| `comments` | comment-analyzer |
| `tests` | pr-test-analyzer |
| `errors` | silent-failure-hunter |
| `types` | type-design-analyzer |
| `code` | code-reviewer |
| `simplify` | code-simplifier |
| `all` or no filter | all 6 roles |

## Aggregated Output Format

```
## PR Review: [scope]

### CRITICAL — must fix before merge
- [role] [file:line] [description]

### IMPORTANT — should fix
- [role] [file:line] [description]

### SUGGESTIONS — nice to have
- [role] [file:line] [description]

### POSITIVE
- [role] [description of what was done well]

### Summary

| Role | Issues | Critical |
|------|--------|---------|
| comment-analyzer | N | X |
| pr-test-analyzer | N | X |
| silent-failure-hunter | N | X |
| type-design-analyzer | N | X |
| code-reviewer | N | X |
| code-simplifier | N | X |
| **Total** | **N** | **X** |

Status: READY FOR PR / NEEDS FIXES (N critical issues)
```

> For quantitative risk scoring (size, complexity, test coverage, dependencies, security) before this review: run `/pr-risk`.
> For two-stage PR review (internal analysis -> human approval -> posting to GitHub): load the `pr-review` skill.

$ARGUMENTS
