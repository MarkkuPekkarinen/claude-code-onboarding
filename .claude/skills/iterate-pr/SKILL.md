---
name: iterate-pr
description: Iterate on a PR until CI passes and review feedback is addressed. Use when fixing CI failures, addressing PR review comments, or running the feedback-fix-push cycle autonomously. Covers LOGAF-scale feedback triage, CI polling, GitHub thread replies, and exit conditions.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
metadata:
  triggers: iterate PR, fix CI, CI failing, PR feedback, address review comments, PR checks failing, make CI green, iterate until green
  related-skills: pr-review, verification-before-completion
  domain: workflow
  role: autonomous
  scope: pr-lifecycle
  output-format: actions
---

# Iterate PR Until CI Passes

Autonomously fixes CI failures and addresses review feedback in a loop until all checks are green and feedback is resolved.

**Requires:** GitHub CLI (`gh`) authenticated, Python `uv` installed.

## Quick Reference

```bash
uv run ${CLAUDE_SKILL_ROOT}/scripts/fetch_pr_checks.py [--pr NUMBER]
uv run ${CLAUDE_SKILL_ROOT}/scripts/fetch_pr_feedback.py [--pr NUMBER]
```

## Workflow Summary (8 Steps)

1. Identify PR (`gh pr view`)
2. Gather review feedback (`fetch_pr_feedback.py`)
3. Handle feedback by LOGAF priority — auto-fix high/medium, ask for low
4. Check CI status (`fetch_pr_checks.py`)
5. Fix CI failures — read logs, trace root cause, fix, run tests
6. Verify locally, commit, push
7. Monitor CI in a poll loop — address new feedback as it arrives
8. Repeat from Step 2 if new feedback required changes

## LOGAF Scale

| Level | Labels | Action |
|-------|--------|--------|
| `high` | `h:`, blocker, changes requested | Auto-fix |
| `medium` | `m:`, standard feedback | Auto-fix |
| `low` | `l:`, nit, style, suggestion | Ask user |
| `bot` | Codecov, Dependabot informational | Skip |
| `resolved` | Already resolved threads | Skip |

Review bot feedback (`review_bot: true`) in high/medium/low — treat as human feedback.

## Reference Files

| File | Contents |
|------|----------|
| `reference/workflow.md` | Full 8-step procedure, GraphQL reply mutation, fallback commands, exit conditions |
| `scripts/fetch_pr_checks.py` | Fetches CI check status + log snippets via `gh` CLI |
| `scripts/fetch_pr_feedback.py` | Fetches PR review comments, categorizes by LOGAF scale |
