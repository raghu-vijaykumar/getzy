# Implementation Plan: Getzy Torrent Downloader

**Spec**: `specs/001-getzy-torrent-downloader/spec.md`  
**Constitution**: `.specify/memory/constitution.md`  
**Target**: Flutter Android app with native torrent engine boundary.

## Technical Context

- **Language/Version**: Dart stable with Flutter stable; Kotlin for Android service and engine bridge.
- **Primary Dependencies**: Flutter Material 3, Riverpod, go_router, drift or sqflite, file_picker, path_provider, permission_handler, connectivity_plus, battery_plus, workmanager or Android foreground service integration.
- **Torrent Engine**: Android native libtorrent adapter through platform channels or FFI.
- **Storage**: SQLite database plus Android document tree or app-specific storage path.
- **Testing**: Flutter unit tests, widget tests, golden tests, integration tests, Kotlin unit tests, engine adapter contract tests.

## Architecture Overview

Getzy is split into four layers:

1. **Presentation**: Flutter screens, dialogs, widgets, themes, and navigation.
2. **Application State**: Riverpod controllers for torrent list, search/sort/filter, settings, feeds, session status, and constraints.
3. **Domain and Persistence**: Immutable models, repositories, SQLite tables, validation, and dedupe logic.
4. **Platform Engine**: Android foreground service, torrent engine adapter, notification bridge, storage permissions, and device/network constraint monitors.

## Project Structure

```text
lib/
  app/
    getzy_app.dart
    router.dart
    theme.dart
  features/
    torrents/
      data/
      domain/
      presentation/
    feeds/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
    session/
      domain/
      presentation/
    engine/
      domain/
      platform/
  shared/
    widgets/
    formatting/
    validation/
android/
  app/src/main/kotlin/.../engine/
test/
  unit/
  widget/
  golden/
integration_test/
```

## Phase 0: Discovery and Decisions

- Validate the preferred libtorrent Flutter integration path: FFI vs platform channels.
- Confirm Android target SDK permissions for notifications, storage, foreground service, and network state.
- Decide SQLite library based on code generation tolerance and testability.
- Pick golden-test strategy for dark UI screenshots.
- Define legal sample torrent fixtures for local and CI tests.

## Phase 1: Flutter Shell and UI

- Create Flutter project scaffold.
- Add Getzy dark Material theme with cyan accent and dense list defaults.
- Build root navigation and routes.
- Build home screen with tabs, toolbar actions, search mode, sort dialog, overflow menu, and add torrent dialog.
- Build reusable setting row, switch row, metric row, and dark dialog components.
- Build settings category list and all settings subpages reflected in screenshots.
- Build feed manager, add-feed dialog, session status screen, advanced network interface dialog, and about screen.

## Phase 2: Domain and Persistence

- Define domain models for torrents, files, feeds, settings, session status, and engine events.
- Implement SQLite schema and migrations.
- Implement repositories for torrents, settings, feeds, and session counters.
- Add validators for magnet URIs, info hashes, torrent URLs, feed URLs, ports, speeds, and paths.
- Implement filtering, sorting, dedupe, queue ordering, and status mapping.

## Phase 3: Engine Adapter

- Define `TorrentEngine` Dart interface with methods for add, pause, resume, remove, move queue, set limits, set session settings, shutdown, and stream events.
- Implement fake engine for tests and UI development.
- Implement Android foreground service bridge.
- Integrate native torrent engine library.
- Map native engine states to Dart domain events.
- Persist and restore active torrents across process restarts.

## Phase 4: Constraints and Background Behavior

- Implement network monitor for Wi-Fi-only and VPN-only behavior.
- Implement battery/charging monitor for charging-only and battery limit rules.
- Implement scheduled start and shutdown.
- Implement notification controls for pause/resume/shutdown.
- Implement storage permission and selected directory handling.
- Implement watched incoming directory where Android storage APIs allow it.

## Phase 5: RSS Feeds

- Implement RSS fetcher with timeout, parsing, and dedupe.
- Persist feed items and cleanup old items.
- Implement manual refresh and configurable interval.
- Implement optional auto-download for feed-published torrents.
- Add feed error states and retry behavior.

## Phase 6: Hardening

- Add accessibility labels for all icon-only controls.
- Add empty states and blocked states.
- Add engine crash recovery and service reconnection.
- Add legal-use onboarding copy and privacy policy content.
- Run performance checks with 500 stored torrents.

## Risk Register

- **Native engine complexity**: mitigate through fake engine first and contract tests.
- **Android background limits**: mitigate with foreground service and explicit notification behavior.
- **Scoped storage restrictions**: mitigate by using Android storage access framework and app-specific defaults.
- **Store policy risk**: mitigate by avoiding search indexes, infringing examples, ads, and analytics.
- **Battery drain**: mitigate with power management settings and visible foreground service.

## Manual QA Checklist

- Add magnet link, local `.torrent`, HTTP `.torrent`, and duplicate torrent.
- Pause/resume one torrent and all torrents.
- Switch tabs, search, sort, and modify queue.
- Kill and reopen app while engine is running.
- Toggle Wi-Fi-only, VPN-only, charging-only, and battery-limit constraints.
- Change storage path and verify permission-denied behavior.
- Add RSS feed, refresh, auto-add item, and cleanup old items.
- Verify session status totals and incoming port warning.
- Verify notification controls and shutdown.
