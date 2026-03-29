# HookBridge Installation

Wires Claude Code's hook system into Peon Notch via `notch-update`.

## Prerequisites

Build `notch-update` first:

```bash
cd ~/Documents/Developer/peon-notch
swift build
```

## Add hooks to ~/.claude/settings.json

Open `~/.claude/settings.json` and merge in the `hooks` block below. Replace `/path/to/peon-notch` with your actual install path (e.g. `/Users/yourname/Documents/Developer/peon-notch`).

```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "echo $CLAUDE_INPUT | /path/to/peon-notch/hooks/notch-bridge.sh SessionStart",
        "timeout": 10,
        "async": true
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "echo $CLAUDE_INPUT | /path/to/peon-notch/hooks/notch-bridge.sh Stop",
        "timeout": 10,
        "async": true
      }
    ],
    "SubagentStart": [
      {
        "type": "command",
        "command": "echo $CLAUDE_INPUT | /path/to/peon-notch/hooks/notch-bridge.sh SubagentStart",
        "timeout": 10,
        "async": true
      }
    ],
    "Notification": [
      {
        "type": "command",
        "command": "echo $CLAUDE_INPUT | /path/to/peon-notch/hooks/notch-bridge.sh Notification",
        "timeout": 10,
        "async": true
      }
    ]
  }
}
```

If `settings.json` already has a `hooks` key, merge the event entries — don't replace the whole block.

## Notes

- All hooks run `async: true` — they never block Claude Code.
- The script silently exits if `notch-update` is not found, so it's safe to install before building.
- These hooks are additive and work alongside any existing hooks (e.g. peon-ping).
- `notch-bridge.sh` has no external dependencies — only bash, grep, and sed (standard macOS).

## Event mapping

| Claude Code hook | Notch event emitted |
|---|---|
| `SessionStart` | `session.start` |
| `Stop` / `SessionEnd` | `session.end` |
| `SubagentStart` | `subagent.start` |
| `Notification` (default) | `task.complete` |
| `Notification` with error/fail in title | `task.error` |
| `Notification` with input/approval in title | `input.required` |

## Verify

Run a smoke test to confirm JSON parsing works:

```bash
echo '{"session_id":"test-123","cwd":"/tmp","title":"Done","message":"All tasks complete"}' \
  | /path/to/peon-notch/hooks/notch-bridge.sh Notification
```

With `notch-update` built and PeonNotch running, the notch widget should update.
