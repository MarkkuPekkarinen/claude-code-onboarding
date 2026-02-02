---
name: changelog
description: Generate a user-facing changelog from recent git commits. Auto-detects project structure, parses conventional commits, filters noise, and outputs polished release notes.
allowed-tools: Bash, Read, Write, Edit
---

# Generate Changelog

Generate a user-facing changelog from git history. Use the `changelog-generator` skill for formatting rules, commit categorization, and output format variants.

## Steps

1. **Detect project** — read `CLAUDE.md` if it exists for stack context. Scan for project files (`pom.xml`, `package.json`, `pubspec.yaml`, `pyproject.toml`, `angular.json`, `Cargo.toml`, `go.mod`, etc.) to identify platforms and build a label map (e.g. "Backend", "Web App", "Mobile App").

2. **Detect range** — find the last git tag. If no tags exist, use the last 7 days:
   ```bash
   LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
   ```

3. **Extract commits** — get structured log (skip merges):
   ```bash
   git log "${LAST_TAG:-$(git log --since='7 days ago' --format='%H' | tail -1)}"..HEAD \
     --pretty=format:"%h|%ai|%an|%s" --no-merges
   ```

4. **Categorize** — map conventional commit prefixes:
   - `feat:` → ✨ New Features
   - `fix:` → 🐛 Bug Fixes
   - `perf:` → ⚡ Performance
   - `BREAKING CHANGE` / `!:` → 🚨 Breaking Changes
   - Skip: `refactor:`, `test:`, `chore:`, `ci:`, `build:`, `style:`

5. **Label by platform** — use commit scopes (e.g. `feat(api):`, `fix(web):`) and file paths from `git diff-tree` to map each commit to the platform detected in step 1. For single-platform repos, skip labels entirely.

6. **Rewrite** — translate each commit into user-friendly language. Strip file paths, class names, function names, and framework-specific jargon. Lead with the user benefit. Use the label map from step 1 for multi-platform releases.

7. **Format** — assemble as Markdown with categories. If `$1` is provided, use it as the version label (e.g., `v2.5.0`). Otherwise label by date.

8. **Output** — print to chat. If the user wants it saved, prepend to `CHANGELOG.md` (newest on top).