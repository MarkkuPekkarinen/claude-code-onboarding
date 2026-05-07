#!/usr/bin/env bash
# PostToolUse (Write|Edit): MCP tool scenario contract reminder.
#
# Fires after every Edit/Write tool call.
# When a file under any mcp/*/src/tools/ directory is modified,
# injects a reminder to update scenarios.yaml and run contract
# validation before opening a PR.

set -euo pipefail

# Read the tool input JSON from stdin
INPUT=$(cat)

# Extract the file path that was just written/edited
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', '') or '')
" 2>/dev/null || true)

# Only act on TypeScript files inside any mcp/*/src/tools/ directory
if ! echo "$FILE_PATH" | grep -qE '.*/mcp/[^/]+/src/tools/[^/]+\.ts$'; then
  exit 0
fi

# Extract just the module name (e.g. geo.ts → geo)
MODULE=$(basename "$FILE_PATH" .ts)

# Detect scenarios.yaml — look for it relative to the mcp package root
# e.g. mcp/my-mcp-server/src/tools/foo.ts → mcp/my-mcp-server/tests/scenarios.yaml
MCP_ROOT=$(echo "$FILE_PATH" | sed 's|/src/tools/[^/]*$||')
SCENARIOS_FILE="${MCP_ROOT}/tests/scenarios.yaml"

if [[ ! -f "$SCENARIOS_FILE" ]]; then
  exit 0
fi

MATCH_COUNT=$(grep -c "^  - tool: ${MODULE}_" "$SCENARIOS_FILE" 2>/dev/null || true)
MATCH_COUNT="${MATCH_COUNT//[$'\t\r\n ']/}"  # strip whitespace/newlines
MATCH_COUNT="${MATCH_COUNT:-0}"

if [[ "$MATCH_COUNT" -eq 0 ]]; then
  # No scenarios at all — hard reminder
  cat <<MSG
{
  "systemMessage": "⚠️  MCP CONTRACT GATE — scenarios.yaml has NO entries for tool module '${MODULE}'.\n\nRequired before PR:\n  1. Add ≥3 scenarios (happy_path + invalid_input + edge_case) to:\n     ${SCENARIOS_FILE}\n  2. Run the validation script in the mcp package\n  3. Exit code must be 0 (GREEN) before commit.\n\nCI gate will block merge if scenarios are absent."
}
MSG
else
  # Scenarios exist — soft reminder to re-run validation
  cat <<MSG
{
  "systemMessage": "ℹ️  MCP tool '${MODULE}' edited — ${MATCH_COUNT} scenario block(s) found in scenarios.yaml.\n\nIf input schema or error behaviour changed, update the affected assert/input blocks in scenarios.yaml, then re-run the validation script.\n\nExit code must be 0 (GREEN) before opening a PR."
}
MSG
fi
