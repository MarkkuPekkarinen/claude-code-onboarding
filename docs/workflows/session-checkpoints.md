# Session Checkpoints

> **When to use**: Before risky refactors, between implementation phases, or to compare before/after state in a long session
> **Command**: `/checkpoint`

## Overview

Named checkpoints save the current git SHA and changed-file list to `.claude/checkpoints.log`. Use them to mark progress points in long sessions so you can verify what changed between phases.

## Workflow

```bash
# Save checkpoint before a risky change
/checkpoint create pre-refactor

# ... make changes ...

# Verify what changed
/checkpoint verify pre-refactor

# List all checkpoints in session
/checkpoint list
```

## Log Format

`.claude/checkpoints.log` — append-only, pipe-separated:
```
2026-03-29T14:22:00Z|pre-refactor|abc1234|7 files changed
2026-03-29T15:45:00Z|phase-1-complete|def5678|3 files changed
```

## When to Checkpoint

- Before any large refactor: `pre-refactor`
- After completing a plan phase: `phase-N-complete`
- Before experimenting with a risky approach: `before-experiment`
- Before running destructive database operations

## Rules

- Checkpoint names: lowercase, hyphens only (no spaces)
- Checkpoints are session-level markers only — not a substitute for git commits
- `/checkpoint clear` requires confirmation before wiping the log

## Related

- Command: `.claude/commands/checkpoint.md`
