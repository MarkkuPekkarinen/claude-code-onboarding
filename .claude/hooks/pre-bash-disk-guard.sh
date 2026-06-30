#!/usr/bin/env bash
# PreToolUse(Bash): advisory LOW-DISK warning before a disk-hungry build/container command.
#
# WHY: image builds, full-stack bring-up, and `--no-cache` rebuilds consume a lot of disk and
# can wipe/repopulate volumes. When the host (or Docker Desktop's VM) disk is low, these fail
# MID-WAY with opaque errors that read like code bugs. This warns *right before* such a command
# so you can free space first. Advisory — ALWAYS exits 0; it never blocks the command.
#
# Thresholds overridable for testing: PH_DISK_WARN_GB (default 30), PH_DISK_CRIT_GB (default 15).
set -uo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null) || TOOL=""
[ "$TOOL" = "Bash" ] || exit 0
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || CMD=""
[ -z "$CMD" ] && exit 0

# Fire ONLY for disk-hungry operations (image builds, full-stack bring-up, no-cache rebuilds).
echo "$CMD" | grep -qiE 'docker[ -]?compose[^|]*(build|up)|docker (build|buildx)|podman build|nerdctl build|--no-cache|vagrant up|minikube start|kind create' || exit 0

WARN_GB="${PH_DISK_WARN_GB:-30}"
CRIT_GB="${PH_DISK_CRIT_GB:-15}"

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
# Portable available space on the repo's filesystem: `df -P -k` → col 4 = available 1024-blocks.
avail_kb=$(df -P -k "$ROOT" 2>/dev/null | awk 'NR==2{print $4}')
case "${avail_kb:-}" in ''|*[!0-9]*) exit 0 ;; esac   # unparseable → silent (never break the flow)
free_gb=$(( avail_kb / 1024 / 1024 ))

if [ "$free_gb" -lt "$CRIT_GB" ]; then
  {
    echo ""
    echo "🛑 LOW DISK: ${free_gb} GB free (< ${CRIT_GB} GB) before a disk-hungry build/container command."
    echo "   A full image rebuild + volume reseed will likely FAIL mid-way with opaque errors."
    echo "   Free space first:  docker system prune -af --volumes"
    echo "   (Measures HOST free space; on macOS Docker Desktop also has its OWN VM disk limit — verify with: docker system df)"
    echo ""
  } >&2
elif [ "$free_gb" -lt "$WARN_GB" ]; then
  {
    echo ""
    echo "⚠️  Low disk: ${free_gb} GB free (< ${WARN_GB} GB) before a build/container command — a full rebuild may not complete."
    echo "   Consider freeing space:  docker system prune -af   (check usage: docker system df)"
    echo ""
  } >&2
fi

exit 0
