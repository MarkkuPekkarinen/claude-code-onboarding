#!/usr/bin/env bash
# UserPromptSubmit hook: Correction Signal Detector
#
# Scans the user's prompt for correction signal patterns defined in CLAUDE.md.
# When detected, injects a hard reminder into context — Claude must write a
# lessons.md entry BEFORE responding to the corrected task.
#
# Correction signals (from CLAUDE.md self-improvement loop):
#   - "that's wrong", "not like that", "you missed X"
#   - User re-states something already said
#   - User explicitly points out a repeated mistake
#   - User overrides a decision made independently

set -uo pipefail

INPUT=$(cat)

# Extract the user prompt text
PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # Handle both string and array message formats
    msg = data.get('message', '') or ''
    if isinstance(msg, list):
        # Extract text content from message array
        parts = [p.get('text','') for p in msg if isinstance(p,dict) and p.get('type')=='text']
        print(' '.join(parts).lower())
    else:
        print(str(msg).lower())
except Exception:
    print('')
" 2>/dev/null || echo "")

if [ -z "$PROMPT" ]; then
    echo '{"continue": true}'
    exit 0
fi

# Correction signal patterns (case-insensitive, already lowercased above)
CORRECTION_PATTERNS=(
    "that's wrong"
    "thats wrong"
    "not like that"
    "you missed"
    "you forgot"
    "wrong version"
    "wrong path"
    "that is wrong"
    "incorrect"
    "you should have"
    "i already said"
    "i told you"
    "again you"
    "you did it again"
    "same mistake"
    "fix this mistake"
    "you need to change"
    "you need to update"
    "you got it wrong"
    "should not have"
    "shouldn't have"
    "don't do that"
    "never do that"
    "stop doing"
    "you misunderstood"
    "that was wrong"
    "undo that"
)

DETECTED=""
for PATTERN in "${CORRECTION_PATTERNS[@]}"; do
    if echo "$PROMPT" | grep -qiF "$PATTERN" 2>/dev/null; then
        DETECTED="$PATTERN"
        break
    fi
done

if [ -n "$DETECTED" ]; then
    cat <<'EOF'
{
  "continue": true,
  "additionalContext": "⚠️  CORRECTION SIGNAL DETECTED in this message.\n\nCLAUDE.md self-improvement loop REQUIRES:\n1. BEFORE doing anything else — open .claude/rules/lessons.md\n2. Check if this mistake already has an entry → increment [xN] counter\n3. If no existing entry → add a new one in the 4-line format\n4. ONLY THEN respond to or fix the correction\n\nThis is not optional. Skipping the lesson write is itself a tracked mistake."
}
EOF
else
    echo '{"continue": true}'
fi
