# Getzy Implementation Plan

**Tech Stack**:
- Dart/Flutter for cross-device UI
- Android foreground service for background execution
- libtorrent (via platform channel) for torrent engine
- SQLite for local persistence
- Material Design 3

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│  Flutter UI (Material 3 Dark Theme)             │
│  ├─ Home (All/Queued/Finished tabs)             │
│  ├─ Feed Manager                                │
│  ├─ Settings (6 categories)                     │
│  └─ Torrent Detail                              │
└────────────┬────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────┐
│  Repositories (Torrent, Feed, Settings)         │
│  ├─ SQLite persistence                          │
│  ├─ State management & caching                  │
│  └─ Business logic (dedupe, cleanup, etc.)      │
└────────────┬────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────┐
│  TorrentEngine Interface (Dart boundary)        │
│  ├─ addTorrent(source)                          │
│  ├─ toggleTorrent(id)                           │
│  ├─ deleteTorrent(id)                           │
│  ├─ reorderQueue([ids])                         │
│  └─ Stream<TorrentEngineEvent>                  │
└────────────┬────────────────────────────────────┘
             │
┌────────────▼────────────────────────────────────┐
│  FakeTorrentEngine (local dev)                  │
│  Native Engine Adapter (Android)                │
│  ├─ Platform Channel (MethodChannel)            │
│  ├─ Kotlin foreground service                   │
│  ├─ libtorrent native binding                   │
│  └─ Event marshalling                           │
└─────────────────────────────────────────────────┘
```

## Implementation Strategy

### Phase 1: Foundation
- Flutter project scaffold with Android enabled
- Dependencies: routing, state mgmt, persistence, permissions
- App shell with router and dark theme

### Phase 2: Domain Models & Persistence
- Domain models: TorrentTask, TorrentFile, status enums, etc.
- SQLite schema and migrations
- Repositories: torrent, feed, settings, session
- Validators: magnets, hashes, URLs, feeds

### Phase 3: Engine Boundary
- Abstract TorrentEngine interface
- FakeTorrentEngine for UI development
- Platform channel skeleton
- (Native engine integration deferred to Phase 4+)

### Phase 4: UI Scaffolding
- Home screen: tabs, search, sort, add torrent dialog
- Torrent detail: files, trackers, peers, delete flow
- Feed manager: list, add, refresh, errors
- Overflow menu: feeds, resume all, pause all, settings, shutdown

### Phase 5: Settings Screens
- 6 settings categories + About screen
- Storage, Bandwidth, Torrent/Network, Privacy/Security, Power, Scheduling
- Each category persists to repository

### Phase 6: Automation
- RSS fetch, parse, dedupe
- Auto-download with regex filters
- Watched directory import (Android 10+)

### Phase 7: Constraints & Background
- Wi-Fi-only, charging-only, VPN-only blocking
- Scheduled start/shutdown
- Foreground service & notification
- Permission denial recovery

### Phase 8: Testing
- Unit tests for validators, formatters, RSS logic, dedupe
- Contract tests for TorrentEngine (fake + native)
- Widget tests for UI components
- Golden tests for dark theme
- Integration tests for state persistence
- Android instrumentation tests
- Performance tests (500 torrent scroll)

### Phase 9: Release
- Legal/privacy onboarding
- App icons, Android manifest, package name
- Build APK for release
- Manual QA checklist
- Release notes

---

**Full detailed plan**: See `specs/001-getzy-torrent-downloader/plan.md`
