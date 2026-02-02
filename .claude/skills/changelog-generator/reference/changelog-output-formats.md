# Changelog Output Formats

Different output formats for various destinations. Choose based on the user's needs.

---

## Standard Markdown (CHANGELOG.md / GitHub Release)

```markdown
# Release Notes -- v2.5.0
_Released: 2025-03-15_

## 🚨 Breaking Changes
- **API v1 Retired** -- All integrations must migrate to API v2 by April 1. See migration guide.

## ✨ New Features
- **Mobile App** -- Offline mode: the app now works without internet and syncs when reconnected
- **Web App** -- Team Workspaces: create separate workspaces per project with role-based access
- **Backend** -- Bulk export endpoint: download all your data at once from Settings -> Export

## ⚡ Performance
- **Backend** -- Product listing API responds 2x faster (Redis caching)
- **Web App** -- Dashboard initial load reduced by 40%

## 🐛 Bug Fixes
- **Mobile App** -- Fixed intermittent logout when resuming the app
- **Web App** -- Fixed dashboard widgets showing stale data after navigation
- **Backend** -- Resolved timezone offset in scheduled notification delivery

## 🔒 Security
- **Backend** -- Authentication tokens now use short-lived JWTs with automatic rotation
```

---

## App Store Style (iOS / Android)

Plain language, no emoji, concise. Keep under 4000 characters.

```
What's New in 2.5.0:

- Team Workspaces -- organize projects with your team
- Keyboard shortcuts for faster navigation
- 2x faster file sync
- Bug fixes and performance improvements
```

---

## Keep a Changelog Format (keepachangelog.com)

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

---

## Internal / Technical

Include commit hashes, authors, and PR references for internal teams.

```markdown
## v2.5.0 (2025-03-15) -- 23 commits, 4 contributors

### Features
- Team Workspaces (a1b2c3d) @alice -- #142
- Keyboard shortcuts (d4e5f6g) @bob -- #156

### Fixes
- Image upload race condition (h7i8j9k) @carol -- #160
- Timezone offset calculation (l0m1n2o) @dave -- #163
```

---

## Slack / Email (Condensed Summary)

Keep to a short highlights-only format suitable for posting in a channel or email body.

```
v2.5.0 Released

Highlights:
- Team Workspaces for project organization
- 2x faster file sync
- 5 bug fixes including upload and timezone issues

Full notes: <link to CHANGELOG.md or GitHub Release>
```
