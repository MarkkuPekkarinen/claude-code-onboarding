#!/usr/bin/env bash
# PreToolUse → Write|Edit|MultiEdit: Soft reminder for env-var SSOT sync.
#
# This hook NEVER blocks — it only prints a reminder to stderr when Claude touches:
#   • One of the canonical env files  → remind to sync the others.
#   • docker-compose.yml              → remind: no ${VAR:-default} fallbacks.
#   • Any Dockerfile                  → remind: no hardcoded config.
#
# Hard enforcement lives in your CI sync check (e.g. scripts/check-env-sync.sh).
#
# Exit 0 always — this is advisory, not blocking.
set -uo pipefail

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null) || file=""

[ -z "$file" ] && exit 0

# Normalize to a repo-relative path for cleaner matching.
rel="${file#"$CLAUDE_PROJECT_DIR/"}"
rel="${rel#/}"

# ─── Env file edit ───────────────────────────────────────────────────────────
case "$rel" in
  .env.example|.env.staging|.env.production)
    other_files=""
    for f in .env.example .env.staging .env.production; do
      [ "$f" = "$rel" ] || other_files+=" • ${f}\n"
    done
    echo "" >&2
    echo "━━━ Env-Var SSOT reminder ━━━" >&2
    echo "Editing: ${rel}" >&2
    echo "" >&2
    echo "If you're ADDING, RENAMING, or REMOVING a key, mirror the change in:" >&2
    printf "%b" "$other_files" >&2
    echo "" >&2
    echo "All three env files must have identical key sets at all times." >&2
    echo "" >&2
    exit 0
    ;;
esac

# ─── docker-compose edit ─────────────────────────────────────────────────────
case "$rel" in
  infra/docker-compose.yml|*/docker-compose.yml|docker-compose.yml)
    echo "" >&2
    echo "━━━ Env-Var SSOT reminder ━━━" >&2
    echo "Editing: ${rel}" >&2
    echo "" >&2
    echo "Hard rules for this file:" >&2
    echo "  • Use bare \${VAR} — NEVER \${VAR:-default} fallbacks." >&2
    echo "  • Every \${VAR} referenced here must exist in .env.example." >&2
    echo "" >&2
    exit 0
    ;;
esac

# ─── Dockerfile edit ─────────────────────────────────────────────────────────
if echo "$rel" | grep -qiE '(^|/)Dockerfile(\.[A-Za-z0-9._-]+)?$'; then
  echo "" >&2
  echo "━━━ Env-Var SSOT reminder ━━━" >&2
  echo "Editing: ${rel}" >&2
  echo "" >&2
  echo "Hard rules for Dockerfiles:" >&2
  echo "  • No hardcoded URLs, hosts, ports, secrets, or API keys." >&2
  echo "  • Use ARG/ENV at build/run time — declare the key in .env.example first." >&2
  echo "" >&2
  exit 0
fi

exit 0
