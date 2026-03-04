# Blackbox — Session Log
# Append-only. See .claude/rules/blackbox-policy.md

<!-- git-snapshot 2026-03-03T16:40:01Z -->
- .claude/settings.json
- .gitignore
- README.md
<!-- end-snapshot -->

<!-- git-snapshot 2026-03-03T20:14:57Z -->
- .claude/settings.json
- README.md
<!-- end-snapshot -->

<!-- git-snapshot 2026-03-03T20:18:51Z -->
- .claude/settings.json
- README.md
- blackbox/session-log.md
<!-- end-snapshot -->

<!-- git-snapshot 2026-03-03T20:20:48Z -->
- .claude/settings.json
- README.md
- blackbox/session-log.md
<!-- end-snapshot -->

<!-- git-snapshot 2026-03-03T20:23:05Z -->
- .claude/settings.json
- README.md
- blackbox/session-log.md
<!-- end-snapshot -->

<!-- git-snapshot 2026-03-03T23:43:40Z -->
- .claude/skills/changelog-generator/SKILL.md
<!-- end-snapshot -->

<!-- git-snapshot 2026-03-03T23:46:02Z -->
- .claude/skills/changelog-generator/SKILL.md
- blackbox/session-log.md
<!-- end-snapshot -->

## 2026-03-03T23:50:00Z
### Decisions
- Created `changelog-automation-tools.md` as a new reference file (not appended to `changelog-workflow.md`) — separate concerns: workflow = Claude on-demand; tools = CI/CD automation
- GitHub Actions trigger set to both `main` and `develop` — `develop` → beta pre-release, `main` → stable release
- `npmPublish: false` in semantic-release config — internal services not published to npm registry
- `NPM_TOKEN` removed from required secrets (not needed when npmPublish is false)
### Constraints Stated by User
- Branching model: `feature/* → develop → main` (PRs merge to develop, develop promoted to main for production)
- QA tests on `develop` environment before promoting to `main`
### Files Modified
- `.claude/skills/changelog-generator/reference/changelog-automation-tools.md` — created with git-cliff, semantic-release, and GitHub Actions release workflow configs
- `.claude/skills/changelog-generator/SKILL.md` — added reference pointer to new automation tools file
### Deferred
- Nothing deferred
---

<!-- git-snapshot 2026-03-03T23:47:35Z -->
- .claude/skills/changelog-generator/SKILL.md
- blackbox/session-log.md
<!-- end-snapshot -->

<!-- git-snapshot 2026-03-03T23:48:06Z -->
- .claude/skills/changelog-generator/SKILL.md
- blackbox/session-log.md
<!-- end-snapshot -->
