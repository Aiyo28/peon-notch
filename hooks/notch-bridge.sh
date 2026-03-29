#!/usr/bin/env bash
# notch-bridge.sh — Claude Code hook → Peon Notch bridge
# Receives JSON on stdin from Claude Code hooks
# Usage: notch-bridge.sh [event_type]
# If event_type not passed as $1, reads hook_event_name from stdin JSON

set -euo pipefail

# Read JSON from stdin
INPUT=$(cat)

# Parse fields (no jq dependency)
parse_field() {
    echo "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"//;s/\"$//" || true
}

session_id=$(parse_field session_id)
cwd=$(parse_field cwd)
title=$(parse_field title)
message=$(parse_field message)
hook_event=$(parse_field hook_event_name)

# Event type: prefer $1 arg, fallback to JSON field
EVENT_TYPE="${1:-${hook_event:-unknown}}"

CLAUDE_PID="${PPID:-0}"

# Map hook event to notch event
case "$EVENT_TYPE" in
    SessionStart)     notch_event="session.start" ;;
    SessionEnd)       notch_event="session.end" ;;
    Stop)             notch_event="task.complete" ;;
    SubagentStart)    notch_event="subagent.start" ;;
    Notification)     notch_event="task.complete" ;;
    *)                notch_event="$EVENT_TYPE" ;;
esac

# Refine Notification events by content
if [ "$EVENT_TYPE" = "Notification" ]; then
    case "${title:-}" in
        *[Ee]rror*|*[Ff]ail*)     notch_event="task.error" ;;
        *[Ii]nput*|*[Aa]pproval*) notch_event="input.required" ;;
        *[Cc]omplete*|*[Dd]one*)  notch_event="task.complete" ;;
    esac
fi

display_message="${message:-${title:-}}"
[ -z "$display_message" ] && display_message="$(basename "${cwd:-}" 2>/dev/null || echo "")"

# Find notch-update binary
NOTCH_UPDATE=""
for candidate in \
    "$HOME/Documents/Developer/peon-notch/.build/debug/notch-update" \
    "$HOME/Documents/Developer/peon-notch/.build/release/notch-update" \
    "/usr/local/bin/notch-update" \
    "$HOME/.local/bin/notch-update"; do
    [ -x "$candidate" ] && NOTCH_UPDATE="$candidate" && break
done

[ -z "$NOTCH_UPDATE" ] && exit 0

"$NOTCH_UPDATE" \
    --session "$session_id" \
    --event "$notch_event" \
    --pid "$CLAUDE_PID" \
    --message "$display_message" &

exit 0
