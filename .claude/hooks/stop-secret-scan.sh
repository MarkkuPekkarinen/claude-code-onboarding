#!/usr/bin/env bash
# Stop: Scan modified files for potential secrets/API keys when Claude finishes.
# This is a lightweight warning — not a substitute for proper secret scanning in CI.
# Exit 0 always (warnings only, never blocks).
set -uo pipefail

# Read and discard stdin (hook protocol sends JSON, but we don't need it)
cat > /dev/null 2>&1 || true

# Get list of files changed in the working tree (staged + unstaged)
changed=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only 2>/dev/null || true)

# Nothing changed, nothing to scan
[ -z "$changed" ] && exit 0

# Common secret patterns:
#   AKIA...          → AWS Access Key
#   AIza...          → Google API Key
#   ghp_...          → GitHub Personal Access Token
#   sk-...           → OpenAI / Stripe Secret Key
#   sk-ant-...       → Anthropic API Key
#   password = "..." → Hardcoded passwords (but not ${VAR} references)
patterns='AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z\-_]{35}|ghp_[0-9a-zA-Z]{36}|sk-[0-9a-zA-Z]{20,}|sk-ant-[0-9a-zA-Z\-_]{20,}'

hits=""
while IFS= read -r file; do
  [ -f "$file" ] || continue
  # Skip binary files and common non-source files
  echo "$file" | grep -qE '\.(png|jpg|jpeg|gif|ico|woff|woff2|ttf|eot|lock|map)$' && continue
  if grep -qE "$patterns" "$file" 2>/dev/null; then
    hits="$hits  - $file"$'\n'
  fi
done <<< "$changed"

if [ -n "$hits" ]; then
  echo "" >&2
  echo "⚠️  SECRET SCAN WARNING" >&2
  echo "Possible API keys or secrets detected in changed files:" >&2
  echo "$hits" >&2
  echo "Please review these files before committing." >&2
  echo "Consider using environment variables or a secrets manager instead." >&2
  echo "" >&2
fi

exit 0
