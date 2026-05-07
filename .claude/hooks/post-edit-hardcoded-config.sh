#!/usr/bin/env bash
# PostToolUse (Write|Edit): Scan Python service files for hardcoded configuration.
#
# Catches violations of the "no hardcoded fallbacks" rule:
#   - insecure=True  hardcoded in OTLP/TLS contexts (should come from Settings)
#   - verify=False   hardcoded in requests/httpx contexts
#   - os.getenv(X) or "hardcoded-fallback" sentinel patterns
#
# Always exits 0 — warning only. Blocking happens at PR creation.

set -uo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null) || FILE_PATH=""

# Only scan Python files in services/ or tests/
[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0
[[ "${FILE_PATH##*.}" != "py" ]] && exit 0
(echo "$FILE_PATH" | grep -qE '^.*/services/') || (echo "$FILE_PATH" | grep -qE '^.*/tests/') || exit 0
echo "$FILE_PATH" | grep -qE '/(__pycache__|\.pyc)' && exit 0

# Checks below apply to production code only — skip test and conftest files
IS_TEST_FILE=false
echo "$FILE_PATH" | grep -qE '/(test_|conftest\.py|tests/)' && IS_TEST_FILE=true

WARNINGS=()

if [[ "$IS_TEST_FILE" == "false" ]]; then

# ── 1. insecure=True hardcoded in production code ─────────────────────────────
# In production observability/TLS code it must be driven by a Settings boolean field.
INSECURE_HARD=$(grep -nE 'insecure\s*=\s*True' "$FILE_PATH" 2>/dev/null || true)
if [[ -n "$INSECURE_HARD" ]]; then
  while IFS= read -r line; do
    WARNINGS+=("HARDCODED_INSECURE: $line")
    WARNINGS+=("  → Use a Settings boolean field (e.g. OTEL_INSECURE) so staging/prod can enforce TLS")
  done <<< "$INSECURE_HARD"
fi

# ── 2. verify=False hardcoded in requests/httpx calls ─────────────────────────
VERIFY_FALSE=$(grep -nE 'verify\s*=\s*False' "$FILE_PATH" 2>/dev/null || true)
if [[ -n "$VERIFY_FALSE" ]]; then
  while IFS= read -r line; do
    WARNINGS+=("HARDCODED_VERIFY_FALSE: $line")
    WARNINGS+=("  → TLS verification must not be disabled unconditionally in service code")
  done <<< "$VERIFY_FALSE"
fi

# ── 3. General sentinel: os.getenv(X) or "hardcoded-fallback" ─────────────────
# Catch: os.getenv("X") or "some-literal" which is equivalent to
# os.getenv("X", "some-literal") but harder to grep.
SENTINEL_OR=$(grep -nE \
  'os\.(getenv|environ\.get)\([^)]+\)\s+or\s+"[^"]+(localhost|memory|127\.0\.0\.1|0\.0\.0\.0)[^"]*"' \
  "$FILE_PATH" 2>/dev/null || true)
if [[ -n "$SENTINEL_OR" ]]; then
  while IFS= read -r line; do
    WARNINGS+=("SENTINEL_FALLBACK: $line")
    WARNINGS+=("  → os.getenv(X) or 'fallback' is the same as os.getenv(X, 'fallback') — use Pydantic Settings instead")
  done <<< "$SENTINEL_OR"
fi

fi # end IS_TEST_FILE == false block

# ── Report ─────────────────────────────────────────────────────────────────────
if [[ ${#WARNINGS[@]} -eq 0 ]]; then
  exit 0
fi

echo ""
echo "⚠️  HARDCODED CONFIG DETECTOR — $(basename "$FILE_PATH")"
echo "   Violations found (no hardcoded infra defaults rule):"
echo ""
for w in "${WARNINGS[@]}"; do
  echo "   $w"
done
echo ""
echo "   Fix: use a Pydantic Settings field with no fallback, or fail-fast os.environ['KEY']."
echo ""

exit 0
