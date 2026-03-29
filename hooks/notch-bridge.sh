#!/usr/bin/env bash
# notch-bridge.sh — Claude Code hook → Peon Notch bridge
# Called by Claude Code hooks, receives JSON on stdin
# Usage: echo '{"session_id":"..."}' | notch-bridge.sh <event_type>

set -euo pipefail

EVENT_TYPE="${1:-unknown}"

# Read JSON from stdin
INPUT=$(cat)

# Parse fields with built-in tools (no jq dependency)
# || true prevents set -e from aborting when grep finds no match
session_id=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"session_id"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
cwd=$(echo "$INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"cwd"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
title=$(echo "$INPUT" | grep -o '"title"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"title"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
message=$(echo "$INPUT" | grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"message"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)

# Get the Claude Code process PID
CLAUDE_PID="${PPID:-0}"

# Map hook event to notch event
case "$EVENT_TYPE" in
    SessionStart)     notch_event="session.start" ;;
    Stop|SessionEnd)  notch_event="session.end" ;;
    SubagentStart)    notch_event="subagent.start" ;;
    Notification)     notch_event="task.complete" ;;
    *)                notch_event="$EVENT_TYPE" ;;
esac

# For Notification events, try to detect the type from title/message
if [ "$EVENT_TYPE" = "Notification" ]; then
    case "$title" in
        *[Ee]rror*|*[Ff]ail*)     notch_event="task.error" ;;
        *[Ii]nput*|*[Aa]pproval*) notch_event="input.required" ;;
        *[Cc]omplete*|*[Dd]one*)  notch_event="task.complete" ;;
    esac
fi

# Build message from available fields
display_message="${message:-$title}"
[ -z "$display_message" ] && display_message="$(basename "$cwd" 2>/dev/null || echo "")"

# Find notch-update binary
NOTCH_UPDATE=""
for candidate in \
    "$HOME/Documents/Developer/peon-notch/.build/debug/notch-update" \
    "$HOME/Documents/Developer/peon-notch/.build/release/notch-update" \
    "/usr/local/bin/notch-update" \
    "$HOME/.local/bin/notch-update"; do
    if [ -x "$candidate" ]; then
        NOTCH_UPDATE="$candidate"
        break
    fi
done

if [ -z "$NOTCH_UPDATE" ]; then
    exit 0  # silently skip if notch-update not found
fi

# Send to notch (background — don't block the hook)
"$NOTCH_UPDATE" \
    --session "$session_id" \
    --event "$notch_event" \
    --pid "$CLAUDE_PID" \
    --message "$display_message" &

exit 0
