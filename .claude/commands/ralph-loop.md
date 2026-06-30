---
description: Start a Ralph Wiggum autonomous iteration loop. Claude works on the task, and when it tries to exit, the stop hook feeds the same prompt back until done. Use for long autonomous tasks, overnight work, or multi-attempt problems.
argument-hint: '"PROMPT" [--max-iterations N] [--completion-promise "TEXT"] [--verify-cmd "COMMAND"]'
---

# Ralph Loop

Start an autonomous iteration loop for the given task.

## Setup

```bash
# Parse arguments and create state file
ARGS="$ARGUMENTS"
PROMPT_PARTS=()
MAX_ITERATIONS=10
COMPLETION_PROMISE="null"
VERIFY_CMD="null"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-iterations)
      MAX_ITERATIONS="$2"; shift 2 ;;
    --completion-promise)
      COMPLETION_PROMISE="$2"; shift 2 ;;
    --verify-cmd)
      VERIFY_CMD="$2"; shift 2 ;;
    *)
      PROMPT_PARTS+=("$1"); shift ;;
  esac
done
PROMPT="${PROMPT_PARTS[*]}"

if [[ -z "$PROMPT" ]]; then
  echo "❌ No prompt provided. Usage: /ralph-loop \"Your task\" --max-iterations 10"
  exit 1
fi

mkdir -p "$CLAUDE_PROJECT_DIR/.claude"

if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  CP_YAML="\"$COMPLETION_PROMISE\""
else
  CP_YAML="null"
fi

if [[ "$VERIFY_CMD" != "null" ]]; then
  VC_YAML="\"$VERIFY_CMD\""
else
  VC_YAML="null"
fi

cat > "$CLAUDE_PROJECT_DIR/.claude/ralph-loop.local.md" <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: $CP_YAML
verify_cmd: $VC_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$PROMPT
EOF

echo ""
echo "🔄 Ralph loop activated!"
echo "   Iteration:   1 of $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo '∞ (unlimited)'; fi)"
if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo "   Promise:     $COMPLETION_PROMISE"
  if [[ "$VERIFY_CMD" != "null" ]]; then
    echo "   Verifier:    $VERIFY_CMD  (must exit 0 — the promise alone will NOT end the loop)"
  fi
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "  To exit: output <promise>$COMPLETION_PROMISE</promise>"
  echo "  ONLY when the statement is GENUINELY TRUE."
  if [[ "$VERIFY_CMD" != "null" ]]; then
    echo "  The loop then runs:  $VERIFY_CMD"
    echo "  Exit happens ONLY if that command returns exit 0."
  fi
  echo "  Do NOT output a false promise to escape."
  echo "═══════════════════════════════════════════════"
fi
echo ""
echo "  Monitor:  head -5 .claude/ralph-loop.local.md"
echo "  Cancel:   /cancel-ralph"
echo ""
```

Work on this task. You will see your previous work in files and git history each iteration.

**RULES:**
1. If `--completion-promise` is set, output `<promise>EXACT_TEXT</promise>` ONLY when the statement is genuinely and completely true
2. Do NOT lie to escape — the loop is designed to run until real completion
3. Use TaskList, git log, and modified files to track progress across iterations
4. **Deterministic completion gate (`--verify-cmd`):** when a verifier command is set, the promise is necessary but NOT sufficient — after you emit `<promise>…</promise>` the stop hook runs the verifier and ends the loop ONLY if it exits 0. A non-zero exit REJECTS the promise and feeds the verifier's output back as your next turn; fix the root cause and re-emit only when it will pass. This keeps the authoritative completion signal in a deterministic check of the world, not your own summary of it. NEVER weaken the verifier to make it pass.

$ARGUMENTS
