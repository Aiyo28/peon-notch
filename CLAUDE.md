# Peon Notch — Agent Protocol

## Context

Native macOS notch companion that shows Claude Code agent status as WC3/SC character portraits with sound feedback. Replaces peon-ping.

| Component | Stack | Constraints |
|-----------|-------|-------------|
| App | Swift / SwiftUI + AppKit | macOS 14+, no Electron, no web views |
| Window | NSPanel (nonactivatingPanel) | Menu bar agent (LSUIElement), no dock icon |
| Sound | AVFoundation | No third-party audio libs |
| IPC | CLI (`notch-update`) | No localhost server |

## Session Protocol

1. **Start:** Read `NEXT.md` + `docs/_context/BRIEF.md`
2. **Check:** Read `TODO.md` if task work planned
3. **Deep dive:** `MASTERPLAN.md` for architectural decisions [D1-D7]
4. **End:** `session-complete` skill auto-runs

## Where to Find Things

| Topic | Location |
|-------|----------|
| Architecture + decisions | `MASTERPLAN.md` (Key Decisions section) |
| Task board | `TODO.md` |
| Phase plan | `ROADMAP.md` |
| PRD + implementation issues | GitHub issues #1-#8 |
| Strategy + research | Vault: `Projects/peon-notch/` |

> Vault = `~/Documents/Developer/knowledge-os/`

## Rules

- **MVP simplicity:** Simplest working code first. No abstractions until needed twice. No premature optimization.
- **No third-party Swift packages** for MVP. Standard library + Apple frameworks only.
- **Character packs are folders:** `characters/{name}/portrait.png` + `sounds/`. Adding a pack = dropping a folder. No registration code.

## Critical Gotchas

1. **NSPanel notch positioning is fragile.** The notch size varies by Mac model (14"/16" MBP, no-notch older Macs). Must detect notch presence and size at runtime, not hardcode coordinates.
2. **`kill -0` requires no special entitlements** but only works for processes owned by the same user. Fine for personal use, but sandboxed distribution would break PID checks.
3. **CLI-to-running-app IPC** — the `notch-update` command needs to communicate with the already-running app. Use `NSDistributedNotificationCenter` or XPC, not file polling.
4. **Menu bar agent apps (`LSUIElement`) don't appear in Cmd-Tab.** This is correct behavior but means the only way to interact is via the notch click target. Make sure the click target is generous.

## Skill Routing

| Use | Skip |
|-----|------|
| apple-dev, brainstorming, implement, tdd, grill-me, spec | webapp-testing, stripe, n8n, social-media-research |
