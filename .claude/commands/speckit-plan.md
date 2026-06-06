---
name: speckit-plan
description: Review the technical implementation plan
---

# Getzy Implementation Plan

**Location**: `.specify/PLAN.md` (and detailed: `specs/001-getzy-torrent-downloader/plan.md`)

## Quick Reference

**Tech Stack**:
- Dart/Flutter for UI
- Android foreground service + libtorrent (native)
- SQLite persistence
- Material Design 3, dark theme

## Architecture Layers

```
┌─ Flutter UI (Material 3 Dark) ──────────────┐
│ Home, Feed Mgr, Settings, Torrent Detail    │
└──┬─────────────────────────────────────────┘
   │
┌──┴─ Repositories (Torrent, Feed, Settings) ─┐
│ SQLite persistence, caching, business logic  │
└──┬───────────────────────────────────────────┘
   │
┌──┴─ TorrentEngine Interface ────────────────┐
│ Abstract boundary to native engine           │
└──┬───────────────────────────────────────────┘
   │
┌──┴─ Platform Layer ─────────────────────────┐
│ FakeTorrentEngine (dev) + Android native    │
└─────────────────────────────────────────────┘
```

## 9 Implementation Phases

1. ✅ **Foundation** — Flutter scaffold, dependencies, app shell
2. ✅ **Domain Models** — TorrentTask, models, SQLite schema
3. ✅ **Engine Boundary** — TorrentEngine interface, FakeTorrentEngine
4. ✅ **UI Scaffolding** — Home, detail, feed manager
5. 🔄 **Settings Screens** — 6 settings categories + About
6. ⬜ **Automation** — RSS, feed auto-download, directory import
7. ⬜ **Constraints** — Wi-Fi-only, battery limits, scheduling, notifications
8. ⬜ **Testing** — Unit, widget, golden, integration tests
9. ⬜ **Release** — Legal onboarding, icons, manifests, APK

## Key Design Principles

- **Clean Architecture**: Separate engine/repository/UI boundaries
- **Privacy First**: No cloud sync, no telemetry
- **Resource Aware**: Battery, data plan, storage optimization
- **Local Only**: SQLite persistence, no backup

See `.specify/PLAN.md` for detailed architecture decisions.
