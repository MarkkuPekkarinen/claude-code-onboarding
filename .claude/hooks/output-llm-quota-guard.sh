#!/usr/bin/env bash
# PostToolUse(Bash): Scan command OUTPUT for an LLM-provider quota / rate-limit error and
# surface it as a BILLING / LIMIT condition, not a code bug.
#
# WHY: AI-dependent projects run commands (tests, eval gates, seed scripts, agents) that call
# an LLM provider. When the provider's quota/credits are exhausted or rate-limited, those
# commands fail with errors that LOOK like code/test failures and get misdiagnosed for a whole
# session. This flags the real cause the instant it appears so the loop stops re-running
# commands that cannot pass until the quota/limit clears.
#
# Provider-agnostic: detects Gemini/Vertex, OpenAI, and Anthropic quota/rate-limit signatures.
# Always exits 0 — advisory (the command already ran). Surfaces to the user (stderr) AND to
# Claude (additionalContext) so the agent itself stops retrying. Mirrors output-secrets-scanner.sh.
set -uo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null) || tool_name=""
[ "$tool_name" != "Bash" ] && exit 0

# tool_response may be a string or object — normalise to string.
content=$(echo "$input" | jq -r '
  if .tool_response | type == "string" then .tool_response
  elif .tool_response.output? then .tool_response.output
  elif .tool_response.content? then .tool_response.content
  else (.tool_response | tostring)
  end // ""
' 2>/dev/null) || content=""
[ -z "$content" ] && exit 0
[ "${#content}" -lt 12 ] && exit 0

# ── High-confidence LLM quota / rate-limit signatures (kept narrow to avoid noise) ──
detected=0
if echo "$content" | grep -qE 'RESOURCE_EXHAUSTED|RATE_LIMIT_EXCEEDED|insufficient_quota|overloaded_error'; then
  detected=1
elif echo "$content" | grep -qiE 'exceeded your current quota|quota exceeded|rate limit (reached|exceeded)|too many requests'; then
  detected=1
elif echo "$content" | grep -qE '\b429\b' \
     && echo "$content" | grep -qiE 'openai|anthropic|claude|gemini|vertex|generativelanguage|aiplatform|googleapis|x-ratelimit'; then
  detected=1
fi
[ "$detected" -eq 0 ] && exit 0

cmd=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null | head -c 120) || cmd=""

MSG="⚠️  LLM API quota / rate-limit error (429 / RESOURCE_EXHAUSTED / insufficient_quota) — this is a BILLING/LIMIT/THROTTLE condition, NOT a code or test failure. Check your provider billing/limits before re-running LLM-dependent commands."
CTX="An LLM-provider quota/rate-limit error appeared in the output of: '${cmd}'. This is almost always a billing/quota/throttle condition (depleted credits, hit rate limit, or model overloaded) — NOT a bug in the code or test under change. STOP: do not retry, re-run, or background LLM-dependent commands; they will keep failing identically until the quota/limit clears (refill credits, raise the limit, or wait out the throttle). Report this to the user as a provider/billing blocker; do not attempt code fixes for it."

{
  echo ""
  echo "$MSG"
  [ -n "$cmd" ] && echo "   Command: $cmd"
  echo ""
} >&2

LOGFILE="${CLAUDE_PROJECT_DIR:-.}/.claude/llm-quota-detected.log"
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "?")
printf '[%s] LLM quota/rate-limit | cmd: %s\n' "$ts" "$cmd" >> "$LOGFILE" 2>/dev/null || true

jq -n --arg msg "$MSG" --arg ctx "$CTX" \
  '{systemMessage: $msg, additionalContext: $ctx, suppressOutput: true}' 2>/dev/null || true

exit 0
