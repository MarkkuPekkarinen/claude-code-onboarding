---
name: changelog
description: Generate a user-facing changelog from recent git commits. Parses conventional commits, filters noise, and outputs polished release notes.
allowed-tools: Bash, Read, Write, Edit
---

# Generate Changelog

Generate a user-facing changelog from git history. Use the `changelog-generator` skill for formatting rules and commit categorization.

## Steps

1. **Detect range** — find the last git tag. If no tags exist, use the last 7 days:
   ```bash
   LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
   ```

2. **Extract commits** — get structured log (skip merges):
   ```bash
   git log "${LAST_TAG:-$(git log --since='7 days ago' --format='%H' | tail -1)}"..HEAD \
     --pretty=format:"%h|%ai|%an|%s" --no-merges
   ```

3. **Categorize** — map conventional commit prefixes:
   - `feat:` → ✨ New Features
   - `fix:` → 🐛 Bug Fixes
   - `perf:` → ⚡ Performance
   - `BREAKING CHANGE` / `!:` → 🚨 Breaking Changes
   - Skip: `refactor:`, `test:`, `chore:`, `ci:`, `build:`, `style:`

4. **Rewrite** — translate each commit into user-friendly language. Remove file paths, function names, and jargon. Lead with the user benefit.

5. **Format** — assemble as Markdown with categories. If `$1` is provided, use it as the version label (e.g., `v2.5.0`). Otherwise label by date.

6. **Output** — print to chat. If the user wants it saved, prepend to `CHANGELOG.md` (newest on top).