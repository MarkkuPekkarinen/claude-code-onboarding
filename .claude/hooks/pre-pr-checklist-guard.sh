#!/usr/bin/env bash
# PreToolUse → Bash: Block gh pr create if the PR body is missing required checklist items.
#
# Checks two things:
# 1. The ## Mandatory CI Gate Checklist section header is present
# 2. All mandatory items match the exact regex patterns that pr-checklist-gate CI uses
#
# This prevents CI failures caused by paraphrased wording that doesn't match the CI regex.
# Works for both single-repo and monorepo layouts — paths in checklist items are project-defined.
# Always exits 0 — blocking is done via JSON output.
set -uo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || command=""

# Act on any PR creation command — gh pr create OR gh api .../pulls
# IMPORTANT: Both paths are enforced. Never use gh api to bypass this hook.
# Use word-boundary checks so strings inside commit messages (-m "...gh pr create...") don't trigger.
# The command must actually INVOKE gh, not merely reference it in a string argument.
IS_PR_CREATE=0
echo "$command" | grep -qE '(^|;|&&|\|\|)\s*gh\s+pr\s+create'  && IS_PR_CREATE=1
echo "$command" | grep -qE '(^|;|&&|\|\|)\s*gh\s+api\s+.*pulls' && IS_PR_CREATE=1
[ "$IS_PR_CREATE" -eq 0 ] && exit 0

# Require a body argument to be present in the command string.
# gh pr create uses --body "...", gh api uses --field body="..."
# In both cases the body content is shell-expanded into the command string.
if ! echo "$command" | grep -qE -- '--body[= ]|[- ]body[= ]'; then
  exit 0
fi

# Check section header
if ! echo "$command" | grep -q "Mandatory CI Gate Checklist"; then
  cat <<'JSON'
{
  "decision": "block",
  "reason": "PR body is missing the '## Mandatory CI Gate Checklist' section.\n\nThe PR template already contains this section at the bottom — copy it exactly from .github/PULL_REQUEST_TEMPLATE.md and fill in each checkbox before running gh pr create."
}
JSON
  exit 0
fi

# Extract the body and run item-level validation with Python
body="$command"

python3 - "$body" <<'PYEOF'
import sys, re, json

body = sys.argv[1]

# ── Checklist gates ──────────────────────────────────────────────────────────
# Each entry: (label, regex_pattern, example_wording)
# Add or remove items to match your project's PULL_REQUEST_TEMPLATE.md.
# Paths like "services/", "src/", etc. should match your repo layout.
# Both monorepo paths (services/backend/, mcp/<name>/) and single-repo paths
# (src/, lib/) are valid — just update the regex and example to match yours.

GATES = [
    # ── Quality gates ──────────────────────────────────────────────────────
    ("All existing tests pass (or N/A)",
     r'- \[x\] All existing tests pass|- \[x\] .*tests pass.*N.A',
     "- [x] All existing tests pass (or `N/A — no code changes`)"),

    ("New logic has test coverage (or N/A)",
     r'- \[x\] New logic has.*test|- \[x\] New.*coverage.*N.A',
     "- [x] New logic has at least 1 happy-path test + 1 error-path test (or `N/A — refactor/docs only`)"),

    ("No hardcoded config or secrets (or N/A)",
     r'- \[x\] .*hardcoded config|- \[x\] .*hardcoded.*N.A',
     "- [x] No hardcoded config or secrets — env vars only (or `N/A — no services/ or config changes`)"),

    ("No dead or duplicate code (or N/A)",
     r'- \[x\] .*dead.*code|- \[x\] .*dead.*N.A',
     "- [x] No dead or duplicate code or unused imports (or `N/A`)"),

    ("Linting / static analysis clean (or N/A)",
     r'- \[x\] Lint|- \[x\] .*lint.*N.A',
     "- [x] Linting / static analysis clean (or `N/A — no code changes`)"),

    # ── Documentation ──────────────────────────────────────────────────────
    ("README.md updated (or N/A)",
     r'- \[x\] `README\.md` updated',
     "- [x] `README.md` updated — mark `N/A — no API/setup/structural changes` if not applicable"),

    ("CHANGELOG.md updated (or N/A)",
     r'- \[x\] `CHANGELOG\.md` updated',
     "- [x] `CHANGELOG.md` updated under `## [Unreleased]` — mark `N/A — infra/docs only` if no changelog applies"),

    ("Changelog format (Keep a Changelog)",
     r'- \[x\] Changelog entry follows \[Keep a Changelog\]',
     "- [x] Changelog entry follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format"),

    ("Version bump (or N/A for docs/test/chore)",
     r'- \[x\] Version bumped following \[Semantic Versioning\]|- \[x\] Version bumped.*N.A.*docs|- \[x\] Version bumped.*N.A.*test|- \[x\] Version bumped.*N.A.*chore',
     "- [x] Version bumped following [Semantic Versioning] — mark `N/A — docs/test/chore` if no version bump needed"),

    # ── Live verification ───────────────────────────────────────────────────
    ("Docker rebuild + redeploy healthy (or N/A)",
     r'- \[x\] \*\*Docker rebuild \+ redeploy\*\*.*healthy|- \[x\] \*\*Docker rebuild.*N.A|- \[x\] Docker rebuild.*N.A',
     "- [x] **Docker rebuild + redeploy**: containers healthy in `docker compose ps` (mark `N/A — no service changes`)"),

    ("Feature/fix verified end-to-end (or N/A)",
     r'- \[x\] \*\*Feature/fix verified end-to-end\*\*|- \[x\] \*\*Feature.*verified.*end-to-end\*\*.*N.A|- \[x\] Feature.*fix.*verified.*N.A',
     "- [x] **Feature/fix verified end-to-end**: feature or fix exercised with a real request; no new ERROR lines in logs (mark `N/A — no service changes`)"),

    # ── Security ───────────────────────────────────────────────────────────
    ("/audit-security APPROVED (or N/A)",
     r'- \[x\] `/audit-security` verdict = \*\*APPROVED\*\*',
     "- [x] `/audit-security` verdict = **APPROVED** — lock document saved (mark `N/A — no auth/crypto/input changes`)"),

    # ── Code review ────────────────────────────────────────────────────────
    ("/review-code APPROVE",
     r'- \[x\] `/review-code` verdict = \*\*APPROVE\*\*',
     "- [x] `/review-code` verdict = **APPROVE**"),
]

failed = []
for label, pattern, example in GATES:
    if not re.search(pattern, body, re.IGNORECASE):
        failed.append((label, example))

if not failed:
    sys.exit(0)

lines = ["PR body has %d mandatory checklist item(s) with missing or wrong wording:" % len(failed), ""]
lines.append("The pr-checklist-gate CI job uses exact regex matching. Copy the exact wording below:")
lines.append("")
for label, example in failed:
    lines.append("  MISSING: %s" % label)
    lines.append("  Use exactly: %s" % example)
    lines.append("")
lines.append("These items are in the ## Mandatory CI Gate Checklist section.")
lines.append("Copy from .github/PULL_REQUEST_TEMPLATE.md — do not paraphrase.")

print(json.dumps({"decision": "block", "reason": "\n".join(lines)}))
PYEOF
