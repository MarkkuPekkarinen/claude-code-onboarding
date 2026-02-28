# Blackbox Policy

At the end of any session where decisions were made, code was written,
or constraints were stated: append ONE entry to `blackbox/session-log.md`.

## Entry Format

```
## {ISO-8601-timestamp}
### Decisions
- [Key architectural or technical decision made]
### Constraints Stated by User
- [Any constraint the user explicitly gave — tech choice, scope limit, deadline]
### Files Modified
- [file path] — [one-line reason]
### Deferred
- [Anything explicitly deferred to a future session]
---
```

## Rules
- Append ONLY — never edit or delete existing entries
- Skip if session was purely conversational (no code, no decisions)
- Keep each entry under 20 lines — summarize, don't transcript
- NEVER load `blackbox/session-log.md` into context unless user explicitly asks
- On month boundary: rename `session-log.md` → `archive-YYYY-MM.md`, create fresh `session-log.md`
