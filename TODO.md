# TODO — Peon Notch

## Phase 1 — Foundation

### Setup
- [ ] Create Xcode project with SPM structure
- [ ] Configure as menu bar agent (LSUIElement)
- [ ] Set deployment target macOS 14+

### Notch Shell (#2)
- [ ] Implement NSPanel with nonactivatingPanel style
- [ ] Anchor panel to notch area (center-top, below notch)
- [ ] Build expand/collapse animation
- [ ] Implement 3-column grid layout for session cards
- [ ] Add auto-expand on incoming event with 4s auto-collapse
- [ ] Handle click-outside to collapse

### CLIReceiver (#2)
- [ ] Implement `notch-update` CLI command parsing
- [ ] Handle arguments: --session, --event, --character, --pid, --message
- [ ] Forward parsed events to SessionManager
- [ ] Launch app if not running on CLI call

### SessionManager (#2)
- [ ] Implement session register/update/remove lifecycle
- [ ] Track per-session: ID, PID, character, status, message, timestamp
- [ ] Map event types to status (session.start→working, task.complete→idle, task.error→error, input.required→input)

### CharacterRegistry (#3)
- [ ] Scan characters/ directory for valid packs
- [ ] Load portrait.png per pack
- [ ] Validate pack structure (portrait required, sounds optional)
- [ ] Provide default placeholder for missing portraits
- [ ] Create 2-3 placeholder packs for testing

### Portrait Display (#3)
- [ ] Replace text cards with portrait images in grid
- [ ] Add character name label below portrait
- [ ] Implement status border colors (green/grey/red/yellow)
- [ ] Handle missing portrait gracefully

### SoundEngine (#4)
- [ ] Implement sound playback via AVFoundation
- [ ] Map event type + character pack to sound file lookup
- [ ] Add volume control (0.0-1.0)
- [ ] Add mute/unmute toggle
- [ ] Implement per-category enable/disable
- [ ] Build spam detection (configurable threshold)
- [ ] Persist settings to JSON file
- [ ] Handle missing sound files silently

### Click-to-Focus (#5)
- [ ] Implement PID → window lookup via NSRunningApplication
- [ ] Activate correct terminal window on portrait click
- [ ] Test with Warp terminal
- [ ] Test with Terminal.app
- [ ] Collapse notch after click-to-focus
- [ ] Handle dead window gracefully

### Heartbeat (#6)
- [ ] Implement 30s timer with kill -0 PID check
- [ ] Remove dead sessions from SessionManager
- [ ] Make heartbeat interval configurable
- [ ] Verify negligible CPU overhead

### HookBridge (#7)
- [ ] Write notch-bridge.sh shell script
- [ ] Map Claude Code hooks: SessionStart, Stop, SubagentStart, Notification
- [ ] Extract session ID and PID from hook environment
- [ ] Call notch-update with correct arguments
- [ ] Write installation instructions for settings.json

### Character Selection (#8)
- [ ] Add character_selection_enabled setting (default: false)
- [ ] Implement terminal prompt for character pick on SessionStart
- [ ] Implement default_character fallback
- [ ] Add rotation mode (sequential/random)
- [ ] Handle empty input (skip → default)
