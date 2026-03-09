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
# Run from repository root
uv run ${CLAUDE_SKILL_ROOT}/scripts/fetch_pr_checks.py [--pr NUMBER]
uv run ${CLAUDE_SKILL_ROOT}/scripts/fetch_pr_feedback.py [--pr NUMBER]
```

## Workflow (8 Steps)

### Step 1 — Identify PR

```bash
gh pr view --json number,url,headRefName
```

Stop immediately if no PR exists for the current branch.

### Step 2 — Gather Review Feedback

```bash
uv run ${CLAUDE_SKILL_ROOT}/scripts/fetch_pr_feedback.py
```

Returns categorized feedback. See the LOGAF Scale section below.

### Step 3 — Handle Feedback by Priority

**Auto-fix without asking:**
- `high` — blockers, security findings, changes requested
- `medium` — standard review feedback

**Prompt user for selection:**
- `low` — present numbered list, ask which to address:
  ```
  Found N low-priority suggestions:
  1. [l] "Rename this variable" — @reviewer in api.py:42
  2. [nit] "Use list comprehension" — @reviewer in utils.py:18
  Which would you like to address? (e.g., "1,2" or "all" or "none")
  ```

**Skip silently:**
- `resolved` — already resolved threads
- `bot` — informational bots (Codecov, Dependabot coverage reports)

**Review bot items** (`review_bot: true`) in high/medium/low: treat as human feedback.
- Real issue → fix it
- False positive → skip, but post a reply explaining why

#### Replying to Comments

After processing each item with a `thread_id`, post a reply using GraphQL:

```bash
gh api graphql -f query='
  mutation($threadId: ID!, $body: String!) {
    addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
      comment { id }
    }
  }' -f threadId="<thread_id>" -f body="<reply>\n\n*— Claude Code*"
```

- Reply format: 1-2 sentences — what changed, why it's not an issue, or acknowledgment
- End every reply with `\n\n*— Claude Code*`
- Before replying: check thread for existing `*- Claude Code*` or `*— Claude Code*` reply — skip if already replied
- If `gh api` fails: log and continue, do NOT block the workflow

### Step 4 — Check CI Status

```bash
uv run ${CLAUDE_SKILL_ROOT}/scripts/fetch_pr_checks.py
```

**Wait for review bots before proceeding:** sentry, warden, cursor, bugbot, seer, codeql — they post actionable feedback. Informational bots (codecov) don't block.

### Step 5 — Fix CI Failures

For each failure in `fetch_pr_checks.py` output:

1. Read `log_snippet` — trace the root cause, not just the symptom
2. Read the relevant source files; check for related issues nearby
3. Fix the root cause with minimal, targeted changes
4. Find existing tests for the affected area; run them
5. If fix introduces behavior not covered by existing tests — extend them (add a test case, not a whole new file)

Do NOT assume the failure from the check name alone. Always read the logs.

### Step 6 — Verify Locally, Then Commit and Push

Before committing:
- Fixed a test failure → re-run that specific test
- Fixed a lint/type error → re-run linter/type-checker on affected files
- Any code fix → run existing tests covering changed code

If local verification fails → fix before pushing. Do NOT push known-broken code.

```bash
git add <specific files>
git commit -m "fix: <descriptive message>"
git push
```

### Step 7 — Monitor CI and Address New Feedback

Poll loop (do not block):

1. `uv run ${CLAUDE_SKILL_ROOT}/scripts/fetch_pr_checks.py` — get current status
2. All checks passed → proceed to exit conditions
3. Any checks failed (none pending) → return to Step 5
4. Checks still pending:
   a. `uv run ${CLAUDE_SKILL_ROOT}/scripts/fetch_pr_feedback.py` — check for new feedback
   b. Address new high/medium feedback immediately (same as Step 3)
   c. If changes needed → commit and push (restarts CI), continue polling
   d. Sleep 30 seconds, repeat from 4a
5. After all checks pass → `sleep 10`, run `fetch_pr_feedback.py` one final time. Address any new high/medium feedback — if changes needed, return to Step 6.

### Step 8 — Repeat

If Step 7 required code changes from new feedback, return to Step 2 for a fresh cycle.

## LOGAF Scale

| Level | Label | Action |
|-------|-------|--------|
| `high` | `h:`, blocker, changes requested | Auto-fix |
| `medium` | `m:`, standard feedback | Auto-fix |
| `low` | `l:`, nit, style, suggestion | Ask user |
| `bot` | Codecov, Dependabot informational | Skip |
| `resolved` | Already resolved threads | Skip |

Review bot feedback (`review_bot: true`) appears in high/medium/low — treat it as human feedback.

## Exit Conditions

**Success:** All checks pass + post-CI feedback re-check is clean (no unaddressed high/medium, including review bots) + user decided on all low items.

**Ask for help:** Same failure after 2 attempts, feedback needs clarification, infrastructure issues.

**Stop:** No PR exists for current branch, branch needs rebase.

## Fallback (if scripts fail)

```bash
gh pr checks --json name,state,bucket,link
gh run view <run-id> --log-failed
gh api repos/{owner}/{repo}/pulls/{number}/comments
```

## Reference Files

| File | Contents |
|------|----------|
| `scripts/fetch_pr_checks.py` | Fetches CI check status + log snippets via `gh` CLI |
| `scripts/fetch_pr_feedback.py` | Fetches PR review comments, categorizes by LOGAF scale |
