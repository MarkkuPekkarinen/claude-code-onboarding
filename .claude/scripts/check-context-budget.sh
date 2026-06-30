#!/usr/bin/env bash
# check-context-budget.sh — Measure the ALWAYS-LOADED context cost of this repo's instruction
# files and lint the rules corpus for structural drift.
#
# WHY: CLAUDE.md + every .claude/rules/*.md (that has no `paths:` frontmatter) is injected into
# EVERY session AND every subagent. That cost is real and grows silently as rules accumulate.
# This makes it VISIBLE and tracks its growth — it does NOT tell you to "trim" (a heavy
# always-loaded design can be intentional). It is a measurement + canary tool.
#
# Usage:
#   bash .claude/scripts/check-context-budget.sh             # report (always exits 0)
#   bash .claude/scripts/check-context-budget.sh --strict     # exit 1 if a hard cap is breached
#   bash .claude/scripts/check-context-budget.sh --baseline   # write current total as the baseline
#
# Token estimate is ~chars/4 (approximate — varies by content).
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

MODE="${1:-report}"
BASELINE_FILE=".claude/context-budget-baseline.txt"

# Per-file hard limit Claude Code enforces on a single instruction file. Over it, the file
# silently fails to load → that governance silently stops applying. Split before you hit it.
CHAR_LIMIT=150000
WARN_AT=120000   # 80% of the split limit — time to plan a split

# Always-loaded set: root CLAUDE.md + every rules file.
FILES=("CLAUDE.md")
while IFS= read -r f; do FILES+=("$f"); done < <(find .claude/rules -maxdepth 1 -name '*.md' 2>/dev/null | sort)

echo "Always-Loaded Context Budget"
echo "============================"
echo "Root: $ROOT"
echo ""
printf "%-48s %10s %9s %7s\n" "FILE (always-loaded)" "BYTES" "~TOKENS" "LINES"
printf "%-48s %10s %9s %7s\n" "------------------------------------------------" "----------" "---------" "-------"

TOTAL_BYTES=0
WARN=0
FAIL=0
ROWS=""
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  b=$(wc -c < "$f" | tr -d ' ')
  ROWS+="${b}	${f}"$'\n'
done

while IFS=$'\t' read -r bytes file; do
  [ -z "${file:-}" ] && continue
  tokens=$((bytes / 4))
  lines=$(wc -l < "$file" | tr -d ' ')
  flag=""
  if [ "$bytes" -gt "$CHAR_LIMIT" ]; then
    flag="  ✗ OVER 150k LOAD LIMIT"; FAIL=$((FAIL + 1))
  elif [ "$bytes" -gt "$WARN_AT" ]; then
    flag="  ⚠ approaching 150k limit"; WARN=$((WARN + 1))
  fi
  printf "%-48s %10d %9d %7d%s\n" "$file" "$bytes" "$tokens" "$lines" "$flag"
  TOTAL_BYTES=$((TOTAL_BYTES + bytes))
done < <(printf '%s' "$ROWS" | sort -rn -k1)

TOTAL_TOKENS=$((TOTAL_BYTES / 4))
echo ""
echo "  Always-loaded total: ${TOTAL_BYTES} bytes  (~${TOTAL_TOKENS} tokens, est chars/4)"
echo "  Files: ${#FILES[@]}  |  loaded into every session AND every subagent"

# ── Growth delta vs optional baseline ────────────────────────────────────────
if [ -f "$BASELINE_FILE" ]; then
  base=$(tr -dc '0-9' < "$BASELINE_FILE")
  if [ -n "$base" ] && [ "$base" -gt 0 ]; then
    delta=$((TOTAL_BYTES - base))
    pct=$(( delta * 100 / base ))
    echo "  Baseline: ${base} bytes  |  delta: ${delta} bytes (${pct}%)"
    if [ "$delta" -gt 0 ] && [ "$pct" -ge 10 ]; then
      echo "  ⚠ Always-loaded cost grew ≥10% since baseline — confirm the growth is intentional."
      WARN=$((WARN + 1))
    fi
  fi
fi
if [ "$MODE" = "--baseline" ]; then
  echo "$TOTAL_BYTES" > "$BASELINE_FILE"
  echo "  → wrote baseline ($TOTAL_BYTES bytes) to $BASELINE_FILE"
fi

echo ""
echo "Summary: ${WARN} warning(s), ${FAIL} over-limit file(s)"
# --strict fails ONLY on the genuine, universal defect: a file over the 150k load limit (over
# it, the file silently stops loading). Size/growth stay advisory — a heavy always-loaded
# design can be intentional.
if [ "$MODE" = "--strict" ] && [ "$FAIL" -gt 0 ]; then
  echo "Status: FAIL — a rules file exceeds the 150k-char load limit; split it before it silently stops loading."
  exit 1
fi
echo "Status: report-only (advisory). Re-run with --strict to fail on a 150k-char breach."
exit 0
