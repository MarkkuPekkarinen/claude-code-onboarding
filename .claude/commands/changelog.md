---
name: changelog
description: Generate a user-facing changelog from recent git commits. Auto-detects project structure, parses conventional commits, filters noise, and outputs polished release notes.
allowed-tools: Bash, Read, Write, Edit
---

# Generate Changelog

Generate a user-facing changelog from git history.

**Version label (optional):** $ARGUMENTS

Use the `changelog-generator` skill for the full workflow — project detection, commit extraction, categorization, rewriting, and output formatting.

If a version label is provided above, use it in the changelog header. Otherwise, label by date.
