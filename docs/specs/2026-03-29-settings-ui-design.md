# Settings UI — Design Spec

## Overview

Settings window accessible via gear icon in notch header (top-right) or right-click menu bar icon → "Settings...". Standard macOS settings window with sidebar navigation, dark appearance, ~600x400px.

## Window Structure

Sidebar (left) + content area (right). Sidebar uses SF Symbols for tab icons.

### Tabs

1. **General** (gear icon)
2. **Sound** (speaker.wave.2)
3. **Notifications** (bell)
4. **Characters** (person.crop.square)

## Tab Designs

### General

| Setting | Control | Default |
|---------|---------|---------|
| Launch at login | Toggle | Off |
| Default character | Dropdown (shows portrait + name) | peon |
| Rotation mode | Segmented picker: Fixed / Sequential / Random | Random |

### Sound

| Setting | Control | Default |
|---------|---------|---------|
| Volume | Slider 0–100% | 50% |
| Mute all | Toggle | Off |
| session.start | Toggle + Preview button | On |
| task.complete | Toggle + Preview button | On |
| task.error | Toggle + Preview button | On |
| input.required | Toggle + Preview button | On |

Preview button plays a random sound from the default character's pack for that category.

### Notifications

| Setting | Control | Default |
|---------|---------|---------|
| Auto-expand duration | Slider 2–10s | 4s |
| session.start expands notch | Toggle | On |
| task.complete expands notch | Toggle | On |
| task.error expands notch | Toggle | On |
| input.required expands notch | Toggle | On |

### Characters

Card grid showing installed packs. Each card:
- Portrait image (64x64)
- Pack name
- Sound count badge
- Audio preview buttons (play sample per category)
- "Active" badge if currently set as default

Bottom bar: "Open Characters Folder" button + "Get More Packs" link (opens peonping.com). Remote pack registry planned for future — will host our own pack catalog.

Click a card → highlights it, shows expanded preview panel on right with larger portrait and all sound categories with play buttons.

## Data Flow

All settings persisted to `~/.config/peon-notch/settings.json` (AppSettings) and `~/.config/peon-notch/sound-settings.json` (SoundSettings). Settings window reads/writes these directly — changes apply immediately (no save button).

## Implementation Notes

- SwiftUI `Window` scene with `NavigationSplitView`
- Dark appearance forced (`.preferredColorScheme(.dark)`)
- Settings window is a separate `NSWindow` — doesn't interfere with the notch panel
- Launch at login via `SMAppService.mainApp` (macOS 13+)
- No new dependencies — all native SwiftUI + AppKit
