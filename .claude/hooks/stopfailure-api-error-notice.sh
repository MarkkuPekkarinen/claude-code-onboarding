#!/usr/bin/env bash
# StopFailure: the turn ended due to a CLAUDE (Anthropic) API error — rate limit, auth,
# billing, max-output-tokens, etc. Surface a specific, actionable notice instead of leaving
# the user to guess. Advisory; always exits 0.
#
# Scope note: this catches ANTHROPIC-side (your Claude Code session) turn failures. An LLM
# quota/rate-limit error that surfaces inside a command's OUTPUT (e.g. your app calling an
# LLM provider in a test/eval) is a different thing — handled by output-llm-quota-guard.sh
# (PostToolUse Bash). The two are complementary.
#
# StopFailure is notification-only (the turn already ended) — it cannot block or inject
# conversation context, so this writes a clear stderr notice + an audit-log line. Wired with
# no matcher (fires on every StopFailure); the error class is read from stdin and classified
# here (the stdin field name varies by version, so we read both `error_type` and `error`).
set -uo pipefail

input=$(cat 2>/dev/null || true)
[ -z "$input" ] && exit 0

etype=$(echo "$input" | jq -r '.error_type // .error // "unknown"' 2>/dev/null) || etype="unknown"
emsg=$(echo "$input" | jq -r '.error_message // ""' 2>/dev/null | head -c 200) || emsg=""

case "$etype" in
  rate_limit)
    advice="Anthropic API rate limit hit. Wait and retry, slow the request rate, or check your plan limits. NOT a code problem — do not 'fix' code for this." ;;
  billing_error)
    advice="Anthropic billing error — check your Claude account billing/credits. Account-level, not a code problem." ;;
  authentication_failed)
    advice="Anthropic authentication failed — re-authenticate (/login or check API key). Not a code problem." ;;
  max_output_tokens)
    advice="Hit max output tokens for the turn. Ask Claude to continue, or split the task into smaller steps." ;;
  server_error)
    advice="Anthropic server error (transient). Retry shortly." ;;
  invalid_request)
    advice="Invalid request to the Anthropic API — inspect the last message / tool call that triggered it." ;;
  *)
    advice="Claude turn ended on an API error (${etype})." ;;
esac

{
  echo ""
  echo "🛑 Turn ended on a Claude API error: ${etype}"
  echo "   ${advice}"
  [ -n "$emsg" ] && echo "   Detail: ${emsg}"
  echo ""
} >&2

LOGFILE="${CLAUDE_PROJECT_DIR:-.}/.claude/api-error-detected.log"
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "?")
printf '[%s] StopFailure: %s | %s\n' "$ts" "$etype" "$emsg" >> "$LOGFILE" 2>/dev/null || true

exit 0
