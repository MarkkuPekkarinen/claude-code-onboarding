---
name: changelog-generator
description: Generate user-facing changelogs from git commit history. Parses conventional commits, categorizes changes, filters noise, and outputs polished release notes. Use when preparing releases, writing app store updates, or maintaining a CHANGELOG.md.
allowed-tools: Bash, Read, Write, Edit
---

# Changelog Generator Skill

Transform git commit history into polished, user-friendly changelogs.

## Workflow

### Step 1 — Determine the Range

Identify which commits to include. Ask the user if unclear.

```bash
# Since last tag (most common — "since last release")
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -n "$LAST_TAG" ]; then
  git log "$LAST_TAG"..HEAD --oneline
else
  echo "No tags found — use date range or commit count instead"
fi

# Between two tags
git log v2.4.0..v2.5.0 --oneline

# Date range
git log --after="2025-03-01" --before="2025-03-15" --oneline

# Last N days
git log --since="7 days ago" --oneline
```

### Step 2 — Extract and Parse Commits

Pull structured commit data:

```bash
# Full structured log: hash | date | author | subject
git log "$LAST_TAG"..HEAD --pretty=format:"%h|%ai|%an|%s" --no-merges
```

### Step 3 — Categorize by Conventional Commit Prefix

Map prefixes to user-facing categories:

| Commit Prefix | Category | Emoji | Include? |
|---------------|----------|-------|----------|
| `feat:` | ✨ New Features | ✨ | ✅ Always |
| `fix:` | 🐛 Bug Fixes | 🐛 | ✅ Always |
| `perf:` | ⚡ Performance | ⚡ | ✅ Always |
| `security:` or `fix(security):` | 🔒 Security | 🔒 | ✅ Always |
| `docs:` | 📝 Documentation | 📝 | ⚠️ Only if user-facing |
| `BREAKING CHANGE` or `!:` | 🚨 Breaking Changes | 🚨 | ✅ Always (top of changelog) |
| `refactor:` | — | — | ❌ Skip |
| `test:` | — | — | ❌ Skip |
| `chore:` | — | — | ❌ Skip |
| `ci:` | — | — | ❌ Skip |
| `build:` | — | — | ❌ Skip |
| `style:` (code style) | — | — | ❌ Skip |

**Non-conventional commits** (no prefix): read the message and categorize by intent. If ambiguous, include under "Improvements".

### Step 4 — Translate Technical → User-Friendly

**Rules for rewriting:**
- Remove file paths, function names, and technical jargon
- Lead with the user benefit, not the code change
- Use active voice: "You can now..." or just state the improvement
- Keep each entry to 1–2 sentences max
- Add context only if the change isn't self-explanatory

**Examples:**

| Raw Commit | User-Facing Entry |
|------------|-------------------|
| `feat(auth): add OAuth2 PKCE flow for mobile` | **Social Login on Mobile** — Sign in with Google and Apple on iOS and Android |
| `fix: resolve race condition in WebSocket reconnect` | Fixed intermittent disconnections during real-time collaboration |
| `perf: add Redis caching layer to /api/products` | Product pages now load 2x faster |
| `fix(ui): correct z-index stacking on modal overlay` | Fixed issue where popups appeared behind other elements |
| `feat: implement batch export endpoint` | **Bulk Export** — Download all your data at once from Settings → Export |

### Step 5 — Assemble the Changelog

**Standard format (Markdown):**

```markdown
# Release Notes — v2.5.0
_Released: 2025-03-15_

## 🚨 Breaking Changes
- **API v1 Retired** — All integrations must upgrade to API v2 by April 1

## ✨ New Features
- **Team Workspaces** — Create separate workspaces per project, invite members, and control access
- **Keyboard Shortcuts** — Press `?` to see all shortcuts. Navigate without touching your mouse

## ⚡ Performance
- File sync is now 2x faster across devices
- Dashboard loads 40% quicker on first visit

## 🐛 Bug Fixes
- Fixed large image uploads failing silently
- Resolved timezone offset in scheduled posts
- Corrected notification badge showing wrong count

## 🔒 Security
- Upgraded authentication tokens to use short-lived JWTs with automatic rotation
```

### Step 6 — Output

Write the result based on what the user needs:

| Destination | Action |
|-------------|--------|
| `CHANGELOG.md` | Prepend to existing file (newest on top) |
| GitHub Release | Output as Markdown block ready to paste |
| App Store | Shorter format, no emoji, plain language, ≤ 4000 chars |
| Slack / Email | Condensed summary with highlights only |
| Internal | Include technical details and commit hashes |

## Output Format Variants

### App Store Style (iOS / Android)
```
What's New in 2.5.0:

• Team Workspaces — organize projects with your team
• Keyboard shortcuts for faster navigation
• 2x faster file sync
• Bug fixes and performance improvements
```

### Keep a Changelog Format (keepachangelog.com)
```markdown
## [2.5.0] - 2025-03-15
### Added
- Team Workspaces for project organization
- Keyboard shortcuts (press ? to view all)
### Changed
- File sync performance improved by 2x
### Fixed
- Large image upload failures
- Timezone offset in scheduled posts
### Security
- Upgraded to short-lived JWT tokens
```

### Internal / Technical
```markdown
## v2.5.0 (2025-03-15) — 23 commits, 4 contributors

### Features
- Team Workspaces (a1b2c3d) @alice — #142
- Keyboard shortcuts (d4e5f6g) @bob — #156

### Fixes
- Image upload race condition (h7i8j9k) @carol — #160
- Timezone offset calculation (l0m1n2o) @dave — #163
```

## Edge Cases

- **Squash merges** — read PR titles from merge commits: `git log --merges --pretty=format:"%h|%s"`
- **Monorepo** — filter by path: `git log --oneline -- packages/api/`
- **No conventional commits** — read each message, categorize by intent, note to user that adopting conventional commits would improve future changelogs
- **Empty range** — inform user: "No commits found in this range"
- **Very large range (100+ commits)** — group by week or sprint, summarize instead of listing every item

## Automation Tip

Suggest to the user: add a `pre-release` hook or CI step that runs this skill automatically when tagging a new version. Pair with the `/changelog` command for quick manual runs.