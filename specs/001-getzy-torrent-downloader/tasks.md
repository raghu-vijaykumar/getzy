# Tasks: Getzy Torrent Downloader

**Input**: `specs/001-getzy-torrent-downloader/spec.md` and `specs/001-getzy-torrent-downloader/plan.md`

## Phase 1: Foundation

- [x] T001 Create Flutter app scaffold in the workspace with Android enabled.
- [x] T002 Add dependencies for state management, routing, persistence, file picking, permissions, connectivity, battery, and testing.
- [x] T003 Add Getzy app shell, router, and dark Material theme.
- [x] T004 Add linting rules and CI-friendly test commands.
- [x] T005 Add legal-use and privacy text assets for onboarding/about.

## Phase 2: Domain Models and Persistence

- [x] T006 Define `TorrentTask`, `TorrentFile`, `TorrentStatus`, `EngineSession`, `AppSettings`, `RssFeed`, and `RssItem` domain models.
- [x] T007 Implement SQLite tables and migrations for torrents, files, settings, feeds, feed items, queue order, and transfer totals.
- [x] T008 Implement repositories for torrents, settings, feeds, and session status.
- [x] T009 Add validators for magnet links, info hashes, torrent URLs, feed URLs, speed limits, port numbers, and paths.
- [x] T010 Add duplicate detection by info hash and pending metadata identity.

## Phase 3: Torrent Engine Boundary

- [x] T011 Define Dart `TorrentEngine` interface and event stream contracts.
- [x] T012 Implement fake torrent engine for local UI development and tests.
- [ ] T013 Add Android foreground service skeleton and platform channel bridge.
- [ ] T014 Integrate native libtorrent-compatible engine behind the Android adapter.
- [ ] T015 Map native engine events to Dart models and persist state changes.
- [ ] T016 Add shutdown, reconnect, and crash-recovery handling.

## Phase 4: Home and Torrent Management UI

- [x] T017 Build home screen toolbar with title, search, add-link, sort, and overflow menu actions.
- [x] T018 Build All, Queued, and Finished tabs with compact torrent rows and progress bars.
- [x] T019 Build add torrent dialog for magnet, info hash, HTTP link, and local file entry.
- [x] T020 Build search mode with focused field and live filtering.
- [x] T021 Build sort dialog with queue number, name, dates, speeds, and ETA.
- [x] T022 Build overflow actions for feeds, resume all, pause all, queue modification, session status, settings, and shutdown.
- [x] T023 Build torrent detail view with file list, trackers, peers, and per-file priority controls.
- [x] T024 Build delete/remove flow with optional delete downloaded files choice.

## Phase 5: Settings Screens

- [x] T025 Build settings category list.
- [x] T026 Build Storage settings with storage path, move-after-download, copy torrent files, and watched directory options.
- [x] T027 Build Bandwidth settings with max download/upload and connection limit controls.
- [x] T028 Build Torrent and Network settings for ports, DHT, LSD, UPnP, NAT-PMP, peer exchange, and uTP.
- [x] T029 Build Privacy & Security settings for VPN-only, encryption, proxy, IP filtering, and usage statistics disabled by default.
- [x] T030 Build Power Management settings for Wi-Fi-only, background running, CPU awake, charging-only, and battery limit.
- [x] T031 Build Scheduling settings for start time, shutdown time, run once, and resume all.
- [x] T032 Build Feeds, Advanced, Network Interface dialog, and About screens.

## Phase 6: RSS and Automation

- [x] T033 Build feed manager list, add-feed dialog, refresh action, and feed error states.
- [x] T034 Implement RSS fetch, parse, dedupe, refresh interval, and old-item cleanup.
- [x] T035 Implement optional feed auto-download behavior.
- [ ] T036 Implement watched incoming directory import where platform permissions allow.

## Phase 7: Constraints and Background Behavior

- [ ] T037 Implement Wi-Fi-only and VPN-only transfer blocking.
- [ ] T038 Implement charging-only and battery-limit transfer blocking.
- [ ] T039 Implement scheduled start and scheduled shutdown.
- [ ] T040 Implement foreground notification with progress and pause/resume/shutdown controls.
- [ ] T041 Implement storage permission denial and recovery states.

## Phase 8: Testing

- [ ] T042 Unit test validators, formatters, sorting, filtering, dedupe, queue ordering, and settings reducers.
- [ ] T043 Unit test RSS parsing, cleanup, auto-download decisions, and feed errors with fixtures.
- [ ] T044 Contract test `TorrentEngine` using fake and native adapter conformance cases.
- [ ] T045 Widget test home tabs, torrent rows, add dialog, search, sort dialog, and overflow menu.
- [ ] T046 Widget test settings category list and each settings subpage.
- [ ] T047 Golden test dark UI for home, dialogs, session status, feed manager, and settings screens.
- [ ] T048 Integration test app startup, add torrent, pause/resume, persistence after restart, and settings enforcement with fake engine.
- [ ] T049 Android instrumentation test foreground service lifecycle, notification controls, permissions, and platform channel reconnect.
- [ ] T050 Performance test 500 torrent rows for scroll, search, and sort responsiveness.

## Phase 9: Release Readiness

- [ ] T051 Add legal-use onboarding and privacy policy screen.
- [ ] T052 Add app icon, package name, Android manifest permissions, and foreground service declarations.
- [ ] T053 Run `flutter analyze`, `flutter test`, golden tests, and integration tests.
- [ ] T054 Run Android debug build and manual QA checklist.
- [ ] T055 Prepare release notes and known limitations.
