#!/usr/bin/env bash
# PreToolUse → Write|Edit|MultiEdit: Block modifications to sensitive files.
# Exit 0 = allow, Exit 2 = block (reason sent to Claude via stderr).
set -uo pipefail

# Read the tool input JSON from stdin
input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null) || file=""

# Skip if no file path detected
[ -z "$file" ] && exit 0

# --- Environment and secret files ---
if echo "$file" | grep -qE '(^|/)\.env($|\..+)'; then
  echo "BLOCKED: Cannot modify .env files. Edit environment files manually to prevent accidental secret exposure." >&2
  exit 2
fi

if echo "$file" | grep -qiE '(secrets\.ya?ml|credentials\.json|service[-_]?account.*\.json)'; then
  echo "BLOCKED: Cannot modify credential/secret files. Edit these manually." >&2
  exit 2
fi

# --- Private keys and certificates ---
if echo "$file" | grep -qE '\.(pem|key|p12|pfx|jks|keystore)$'; then
  echo "BLOCKED: Cannot modify key/certificate files. Handle these manually." >&2
  exit 2
fi

# --- Lock files (prevent accidental corruption) ---
if echo "$file" | grep -qE '(package-lock\.json|pnpm-lock\.yaml|yarn\.lock|pubspec\.lock|poetry\.lock)$'; then
  echo "BLOCKED: Cannot directly edit lock files. Use the package manager (npm install, flutter pub get, etc.) instead." >&2
  exit 2
fi

# All clear
exit 0
