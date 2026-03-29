# Peon Notch — Master Plan

> Native macOS notch companion that shows Claude Code agent status as WC3/SC character portraits with sound feedback.

**Repo:** `peon-notch/`
**Vault:** `Projects/peon-notch/_context.md`
**Last Updated:** 2026-03-29
**Current Phase:** Phase 1 — Foundation
**Status:** In Development

## The Problem

Running multiple Claude Code sessions gives zero visual feedback. You can't tell which agents are active, idle, erroring, or waiting for input without switching to each terminal. The current solution (peon-ping) is audio-only with ephemeral overlay banners — no persistent status, no session awareness, no click-to-focus.

## The Vision

Glance at your Mac's notch. See your agents. Know what's happening. Click to jump. Hear the Peon say "work complete." Never check terminals blindly again.

## Who It's For

**Primary:** Developers running 2-6 concurrent Claude Code sessions who want ambient awareness without tab-switching.

**Out of scope:** Non-Mac users. Developers who need a full session manager (this is ambient status, not a terminal multiplexer).

## How It Works

1. Start a Claude Code session → hook fires → character appears in the notch
2. Agent works → portrait shows "working" state (green border)
3. Agent finishes/errors/needs input → notch pulses, sound plays, status updates
4. Click portrait → terminal with that session comes to front
5. Session ends or process dies → character disappears

## Key Decisions

- **[D1] Display surface: Notch overlay, not bottom-of-screen.** Bottom overlay conflicts with terminal input area. Notch is dead space, always visible, no conflicts. Resolved during grilling.
- **[D2] Character art: Static WC3 portraits, not animated sprites.** At notch scale (~120px cards), sprite animations are invisible. Portraits + notch animation carry the feedback. 80% charm at 20% effort.
- **[D3] Standalone app, not peon-ping extension.** Clean break avoids sync complexity between two systems. One app handles both visual and audio. Peon-ping's shell architecture doesn't support native UI.
- **[D4] Communication: CLI command push, not file polling.** Hooks already fire on every Claude Code event. Adding `notch-update` CLI call is simpler and more real-time than polling JSONL or `.state.json`.
- **[D5] Character selection: Hook-based pick on SessionStart with settings toggle.** When enabled, terminal prompt lists characters. When disabled, auto-assigns default. No GUI picker needed for MVP.
- **[D6] Dead session cleanup: 30s PID heartbeat via `kill -0`.** Catches crashes and force-kills. Configurable interval. Negligible overhead.
- **[D7] Grid layout: 3-column, cap at 9 visible.** Covers 99% of use cases (2-6 concurrent sessions). Overflow indicator for edge cases, no infinite scroll in a notch dropdown.

## Business Model

Personal tool first. If published: free open-source with attribution to peon-ping creator. No monetization planned.

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| UI | SwiftUI | Native macOS, lightweight, declarative |
| Window | AppKit NSPanel | nonactivatingPanel for floating, click-through notch |
| Sound | AVFoundation | Native audio, device routing, no dependencies |
| IPC | CLI (notch-update) | Zero-dependency, any agent can call it |
| Hooks | Shell scripts | Matches Claude Code's hook system |
| Build | Xcode / SPM | Standard Swift toolchain |

## Project Structure

```
peon-notch/
├── PeonNotch/                  # Xcode project
│   ├── App/                    # App entry, menu bar agent
│   ├── NotchPanel/             # NSPanel + SwiftUI views
│   ├── SessionManager/         # Session state + heartbeat
│   ├── SoundEngine/            # Audio playback + spam detection
│   ├── CharacterRegistry/      # Pack loading + portraits
│   └── CLIReceiver/            # notch-update command handler
├── hooks/                      # Claude Code hook scripts
│   └── notch-bridge.sh         # HookBridge shell script
├── characters/                 # Character packs
│   ├── peon/                   # portrait.png + sounds/
│   ├── grunt/
│   └── marine/
├── MASTERPLAN.md
├── TODO.md
└── ROADMAP.md
```

## Phase 1 — Foundation

**Goal:** A working notch that shows Claude Code sessions and plays sounds.

**What It Delivers:** Developer sees active sessions in the notch, hears event sounds, clicks to jump to terminal.

**Core Features:**
- Notch panel (expand/collapse, 3-column grid)
- CLI receiver (`notch-update` command)
- Session manager with PID heartbeat
- Character portraits display
- Sound engine with volume/spam/categories
- Click-to-focus terminals
- Claude Code hook bridge
- Character selection (hook pick + default)

**Out of Scope:** Other agent support, settings UI, character pack marketplace.

**Success Criteria:**
- [ ] Notch shows active Claude Code sessions with WC3 portraits
- [ ] Sounds play on events matching the session's character
- [ ] Click portrait → correct terminal focuses
- [ ] Dead sessions auto-removed within 30s
- [ ] Can run 6 concurrent sessions without UI issues

## Phase 2 — Polish

**Goal:** Settings UI and additional character packs.

**What It Delivers:** User configures preferences without editing JSON. More characters to choose from.

**Core Features:**
- Settings window (volume, categories, heartbeat interval, default character)
- Additional WC3/SC character packs (8-12 total)
- Notification history (last N events per session)
- Auto-update mechanism

**Out of Scope:** Multi-agent support, cloud sync.

## Phase 3 — Universal Agent Support

**Goal:** Any terminal AI agent can report status to Peon Notch.

**What It Delivers:** Cursor, Windsurf, Codex users can use Peon Notch too.

**Core Features:**
- Agent adapters (Cursor, Windsurf, Codex)
- Agent-type icons alongside character portraits
- Documentation for third-party integration via CLI protocol

## Future Vision

- Community character pack repository
- Animated portrait reactions (subtle idle breathing, talking on active)
- Multi-monitor notch support
- iOS companion app (see agent status on phone)
- Integration with NotchNook ecosystem

## Constraints

- **macOS only** — uses AppKit NSPanel, no cross-platform
- **No Electron** — native Swift only, minimal resource usage
- **No web server** — CLI-based IPC, no localhost
- **WC3/SC assets for personal use only** — legal review required before public release
- **No terminal emulator features** — this is a status display, not a terminal

## Success Metrics

| Metric | Phase 1 Target |
|--------|---------------|
| Daily active use | Used every coding session |
| Session detection accuracy | 100% of hook-fired events shown |
| Dead session cleanup | <30s after process death |
| Sound latency | <200ms from event to playback |
| Memory footprint | <50MB resident |

## Open Decisions

- [ ] WC3 portrait asset sourcing (extract from game files vs. fan art vs. AI-generated pixel art)
- [ ] Blizzard fan content policy review (before any public release)
- [ ] Peon-ping attribution format (README credit vs. license mention)
