#!/bin/bash

# Ralph Wiggum Stop Hook
# Prevents session exit when a ralph-loop is active.
# Feeds the same prompt back to Claude to continue iterating.
# Exits 0 immediately if no loop is active — zero interference with normal workflow.

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Check if ralph-loop is active — exit immediately if not
RALPH_STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/ralph-loop.local.md"

if [[ ! -f "$RALPH_STATE_FILE" ]]; then
  exit 0
fi

# Parse YAML frontmatter (between --- markers)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$RALPH_STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')
VERIFY_CMD=$(echo "$FRONTMATTER" | grep '^verify_cmd:' | sed 's/^verify_cmd: *//' | sed 's/^"\(.*\)"$/\1/' || true)

# Validate iteration is a number
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Ralph loop: State file corrupted — 'iteration' is not a number (got: '$ITERATION')" >&2
  echo "   Stopping loop. Run /ralph-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Validate max_iterations is a number
if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Ralph loop: State file corrupted — 'max_iterations' is not a number (got: '$MAX_ITERATIONS')" >&2
  echo "   Stopping loop. Run /ralph-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Progress state file (survives loop end — written by Claude per RULES in ralph-loop.md)
RALPH_PROGRESS_FILE="$CLAUDE_PROJECT_DIR/.claude/ralph-state.local.md"

# Check iteration limit
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "🛑 Ralph loop: Max iterations ($MAX_ITERATIONS) reached. Stopping." >&2
  if [[ -f "$RALPH_PROGRESS_FILE" ]]; then
    echo "   Progress + escalated items: .claude/ralph-state.local.md" >&2
  fi
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")

if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  Ralph loop: Transcript not found — stopping loop." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Get last assistant message text
LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>/dev/null || echo "")

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "⚠️  Ralph loop: No assistant output found — stopping loop." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Check for completion promise
VERIFY_FEEDBACK=""
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    # Promise asserted. If a deterministic verifier is configured, IT — not the
    # model's self-report — decides completion. The worker controls what reaches
    # this hook (the transcript); a deterministic command checks the world itself.
    # (mirrors the /goal verifier rule in leverage-patterns.md.)
    if [[ "$VERIFY_CMD" != "null" ]] && [[ -n "$VERIFY_CMD" ]]; then
      VERIFY_LOG="${RALPH_STATE_FILE}.verify.$$"
      RUN_PREFIX=""
      if command -v timeout >/dev/null 2>&1; then
        RUN_PREFIX="timeout 1800"
      fi
      if ( cd "$CLAUDE_PROJECT_DIR" && $RUN_PREFIX bash -c "$VERIFY_CMD" ) >"$VERIFY_LOG" 2>&1; then
        VERIFY_RC=0
      else
        VERIFY_RC=$?
      fi
      if [[ $VERIFY_RC -eq 0 ]]; then
        echo "✅ Ralph loop: Promise '$COMPLETION_PROMISE' + verifier ('$VERIFY_CMD') exit 0. Loop complete." >&2
        if [[ -f "$RALPH_PROGRESS_FILE" ]]; then
          echo "   Run summary + lessons: .claude/ralph-state.local.md" >&2
        fi
        rm -f "$VERIFY_LOG"
        rm "$RALPH_STATE_FILE"
        exit 0
      fi
      # Verifier FAILED — reject the promise, keep iterating with the evidence.
      VERIFY_TAIL=$(tail -n 25 "$VERIFY_LOG" 2>/dev/null || echo "")
      rm -f "$VERIFY_LOG"
      echo "⛔ Ralph loop: Promise asserted but verifier '$VERIFY_CMD' exited $VERIFY_RC — rejecting promise, continuing." >&2
      VERIFY_FEEDBACK="⛔ DETERMINISTIC VERIFIER FAILED. You emitted the completion promise, but \`$VERIFY_CMD\` exited ${VERIFY_RC} (non-zero), so the promise is REJECTED and the work is NOT done. Do NOT emit the promise again until \`$VERIFY_CMD\` exits 0 — and never weaken the verifier to force a pass. Last 25 lines of verifier output:
${VERIFY_TAIL}"
    else
      echo "✅ Ralph loop: Promise detected — '$COMPLETION_PROMISE'. Loop complete." >&2
      if [[ -f "$RALPH_PROGRESS_FILE" ]]; then
        echo "   Run summary + lessons: .claude/ralph-state.local.md" >&2
      fi
      rm "$RALPH_STATE_FILE"
      exit 0
    fi
  fi
fi

# Not done — continue loop
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt body (everything after the second ---)
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$RALPH_STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️  Ralph loop: No prompt text in state file — stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Update iteration counter atomically
TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$RALPH_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$RALPH_STATE_FILE"

# Build system message
STATE_REMINDER="Read .claude/ralph-state.local.md first; update it before ending this iteration. 3 failed attempts on a sub-task = escalate, never retry."
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="🔄 Ralph iteration $NEXT_ITERATION / $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo '∞'; fi) | Output <promise>$COMPLETION_PROMISE</promise> ONLY when genuinely true | $STATE_REMINDER"
else
  SYSTEM_MSG="🔄 Ralph iteration $NEXT_ITERATION / $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo '∞'; fi) | No completion promise set | $STATE_REMINDER"
fi

# If a verifier rejected the promise this turn, lead the next turn with that evidence.
if [[ -n "$VERIFY_FEEDBACK" ]]; then
  FEED_PROMPT="${VERIFY_FEEDBACK}

---

${PROMPT_TEXT}"
else
  FEED_PROMPT="$PROMPT_TEXT"
fi

# Block exit and feed prompt back
jq -n \
  --arg prompt "$FEED_PROMPT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
