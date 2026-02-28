#!/usr/bin/env bash
# Stop hook: Append git-changed files to blackbox/session-log.md as a
# mechanical backup record. Handles auto-creation and monthly rotation.
# Always exits 0 (never blocks).
set -uo pipefail

# Discard stdin JSON from hook protocol
cat > /dev/null 2>&1 || true

LOGFILE="$CLAUDE_PROJECT_DIR/blackbox/session-log.md"
CURRENT_MONTH=$(date -u +"%Y-%m")

# Auto-create blackbox/session-log.md if it doesn't exist
if [ ! -f "$LOGFILE" ]; then
    mkdir -p "$CLAUDE_PROJECT_DIR/blackbox"
    printf "# Blackbox — Session Log\n# Append-only. See .claude/rules/blackbox-policy.md\n" > "$LOGFILE"
fi

# Log rotation: if first entry month differs from current month, archive and start fresh
FIRST_MONTH=$(grep -m1 "^## [0-9]" "$LOGFILE" | grep -oE "[0-9]{4}-[0-9]{2}" | head -1 || true)
if [ -n "$FIRST_MONTH" ] && [ "$FIRST_MONTH" != "$CURRENT_MONTH" ]; then
    mv "$LOGFILE" "$CLAUDE_PROJECT_DIR/blackbox/archive-${FIRST_MONTH}.md"
    printf "# Blackbox — Session Log\n# Append-only. See .claude/rules/blackbox-policy.md\n" > "$LOGFILE"
fi

# Get list of files changed in this session
changed=$(git -C "$CLAUDE_PROJECT_DIR" diff --name-only HEAD 2>/dev/null | head -20 || true)
[ -z "$changed" ] && exit 0

# Append git snapshot entry
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
{
    printf "\n<!-- git-snapshot %s -->\n" "$timestamp"
    echo "$changed" | sed 's/^/- /'
    printf "<!-- end-snapshot -->\n"
} >> "$LOGFILE" 2>/dev/null || true

exit 0
