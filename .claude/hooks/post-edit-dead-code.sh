#!/usr/bin/env bash
# PostToolUse (Write|Edit): Scan Python service files for dead code and unused imports.
#
# Catches:
#   - Unused imports (ruff F401)
#   - Redefined symbols / duplicate imports (ruff F811)
#   - Unused local variables (ruff F841)
#
# Always exits 0 — warning only. Blocking happens at PR creation via pre-pr checks
# and any GATE-2 equivalent (e.g. scripts/check-dead-code.sh).

set -uo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null) || FILE_PATH=""

# Only scan Python files in services/ (not tests, not generated files)
[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0
[[ "${FILE_PATH##*.}" != "py" ]] && exit 0
echo "$FILE_PATH" | grep -qE '^.*/services/' || exit 0
echo "$FILE_PATH" | grep -qE '/(test_|tests/|__pycache__|\.pyc)' && exit 0

WARNINGS=()

# ── 1. Unused imports (F401) ──────────────────────────────────────────────────
F401=$(uv run ruff check "$FILE_PATH" --select F401 --output-format=text --no-cache 2>/dev/null \
  | grep -v "^Found\|^All checks" || true)
if [[ -n "$F401" ]]; then
  while IFS= read -r line; do
    WARNINGS+=("UNUSED_IMPORT: $line")
  done <<< "$F401"
fi

# ── 2. Redefined symbols / duplicate imports (F811) ───────────────────────────
F811=$(uv run ruff check "$FILE_PATH" --select F811 --output-format=text --no-cache 2>/dev/null \
  | grep -v "^Found\|^All checks" || true)
if [[ -n "$F811" ]]; then
  while IFS= read -r line; do
    WARNINGS+=("REDEFINED_SYMBOL: $line")
  done <<< "$F811"
fi

# ── 3. Unused local variables (F841) ─────────────────────────────────────────
F841=$(uv run ruff check "$FILE_PATH" --select F841 --output-format=text --no-cache 2>/dev/null \
  | grep -v "^Found\|^All checks" || true)
if [[ -n "$F841" ]]; then
  while IFS= read -r line; do
    WARNINGS+=("UNUSED_VARIABLE: $line")
  done <<< "$F841"
fi

# ── Report ─────────────────────────────────────────────────────────────────────
if [[ ${#WARNINGS[@]} -eq 0 ]]; then
  exit 0
fi

echo ""
echo "⚠️  DEAD CODE DETECTOR — $(basename "$FILE_PATH")"
echo "   Violations found (no dead code or unused imports rule):"
echo ""
for w in "${WARNINGS[@]}"; do
  echo "   $w"
done
echo ""
echo "   Fix: remove unused imports/variables, or use ruff --fix for auto-fixes."
echo ""

exit 0
