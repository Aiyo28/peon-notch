---
title: "Peon Notch — Brief"
type: project-context
project: peon-notch
created: 2026-03-29
updated: 2026-03-29
status: active
---

# Peon Notch — Brief

## What

Native macOS app anchored to the notch area. Shows active Claude Code sessions as WC3/StarCraft character portraits in a 3-column grid. Plays character-specific sounds on agent events (complete, error, input needed). Click a portrait to focus that terminal. Replaces peon-ping entirely with unified visual + audio feedback.

## Current Phase

Phase 1 — Foundation. Building the core: notch panel, CLI receiver, session manager, character portraits, sound engine, click-to-focus, hook bridge, character selection.

## Active Work

GitHub issues #2-#8 track vertical implementation slices. #2 (Notch Shell + CLI + SessionManager) is the foundation — all others depend on it.

## Key Decisions

See MASTERPLAN.md [D1]-[D7]. All resolved during grilling session 2026-03-29.
