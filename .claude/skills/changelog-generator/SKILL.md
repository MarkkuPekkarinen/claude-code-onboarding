---
name: changelog-generator
description: Generate user-facing changelogs from git commit history. Parses conventional commits, categorizes changes, filters noise, and outputs polished release notes. Use when preparing releases, writing app store updates, or maintaining a CHANGELOG.md.
allowed-tools: Bash, Read, Write, Edit
---

# Changelog Generator Skill

Transform git commit history into polished, user-friendly changelogs. Works with any tech stack by auto-detecting the project structure.

## Step 0 — Detect Project Structure

Before processing commits, scan the repo to understand what's in it. This makes platform labels and commit rewrites accurate regardless of stack.

```bash
# Detect project modules / platforms by presence of key files
echo "=== Project Detection ==="
[ -f pom.xml ] || [ -f build.gradle.kts ] && echo "JAVA_BACKEND=true"
[ -f package.json ] && grep -q '"express"\|"fastify"\|"hono"\|"koa"' package.json 2>/dev/null && echo "NODE_BACKEND=true"
[ -f pyproject.toml ] || [ -f requirements.txt ] && echo "PYTHON_BACKEND=true"
[ -f angular.json ] && echo "ANGULAR_FRONTEND=true"
[ -f next.config.* ] 2>/dev/null && echo "NEXT_FRONTEND=true"
[ -f vite.config.* ] 2>/dev/null && echo "VITE_FRONTEND=true"
[ -f pubspec.yaml ] && echo "FLUTTER_MOBILE=true"
[ -f Cargo.toml ] && echo "RUST_PROJECT=true"
[ -f go.mod ] && echo "GO_PROJECT=true"

# Detect monorepo structure
[ -f lerna.json ] || [ -f pnpm-workspace.yaml ] || [ -d packages/ ] && echo "MONOREPO=true"

# Read CLAUDE.md for additional context if available
[ -f CLAUDE.md ] && echo "--- CLAUDE.md available for project context ---"
```

**Use detection results to:**
1. Build a platform label map (e.g. `lib/` → **Mobile App**, `src/app/` → **Web App**)
2. Identify the right path filters for monorepo/multi-module changelogs
3. Translate framework-specific jargon accurately (e.g. "state provider" → state management, "reactive stream" → async endpoint, "API router" → API endpoint)

If `CLAUDE.md` exists, read it first — it describes the project's tech stack, conventions, and folder structure which will improve rewrite accuracy.

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
| `feat(api): add OAuth2 PKCE flow to AuthController` | **Backend** — Social login now supports Google and Apple sign-in |
| `fix(web): resolve state update race in DashboardComponent` | **Web App** — Fixed dashboard widgets occasionally showing stale data |
| `perf: add caching layer to /api/v1/products endpoint` | **Backend** — Product listing API responds 2x faster |
| `feat(mobile): implement offline-first data sync` | **Mobile App** — App now works offline and syncs when reconnected |
| `fix(db): correct migration column default for preferences` | Fixed user preferences resetting after account update |
| `feat: add batch processing endpoint` | Bulk operations now available via a single API call |
| `fix(mobile): correct auth state lifecycle on app resume` | **Mobile App** — Fixed intermittent logout on app resume |

**Rewriting rules:**
- Strip file paths, class names, function names, and framework internals
- Lead with the **user benefit**, not the code change
- Use active voice: "You can now..." or just state the improvement
- Keep each entry to 1–2 sentences max
- Use the platform label from Step 0 when the release spans multiple platforms
- For single-platform repos, skip the label entirely

### Step 5 — Assemble the Changelog

**Standard format (Markdown):**

```markdown
# Release Notes — v2.5.0
_Released: 2025-03-15_

## 🚨 Breaking Changes
- **API v1 Retired** — All integrations must migrate to API v2 by April 1. See migration guide.

## ✨ New Features
- **Mobile App** — Offline mode: the app now works without internet and syncs when reconnected
- **Web App** — Team Workspaces: create separate workspaces per project with role-based access
- **Backend** — Bulk export endpoint: download all your data at once from Settings → Export

## ⚡ Performance
- **Backend** — Product listing API responds 2x faster (Redis caching)
- **Web App** — Dashboard initial load reduced by 40%

## 🐛 Bug Fixes
- **Mobile App** — Fixed intermittent logout when resuming the app
- **Web App** — Fixed dashboard widgets showing stale data after navigation
- **Backend** — Resolved timezone offset in scheduled notification delivery

## 🔒 Security
- **Backend** — Authentication tokens now use short-lived JWTs with automatic rotation
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
- **Monorepo / multi-module** — use the paths detected in Step 0 to filter. Example:
  ```bash
  # Filter commits to a specific module (paths vary per project)
  git log --oneline -- path/to/module/
  ```
- **No conventional commits** — read each message, categorize by intent, note to user that adopting conventional commits would improve future changelogs
- **Empty range** — inform user: "No commits found in this range"
- **Very large range (100+ commits)** — group by week or sprint, summarize instead of listing every item

## Automation Tip

Suggest to the user: add a `pre-release` hook or CI step that runs this skill automatically when tagging a new version. Pair with the `/changelog` command for quick manual runs.