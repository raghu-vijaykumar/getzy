# Feature Specification: Getzy Torrent Downloader

**Feature Branch**: `001-getzy-torrent-downloader`  
**Created**: 2026-06-06  
**Status**: Draft  
**Input**: User request: "create a torrent downloader called Getzy ... similar fully functional torrent downloader in Flutter" with screenshots of a Flud-like Android UI.

## User Scenarios and Testing

### Primary User Story

As an Android user, I want Getzy to add, manage, search, sort, and monitor torrents with a dark mobile UI so I can control lawful torrent downloads from one app.

### Acceptance Scenarios

1. **Given** the app has queued torrents, **When** the user opens Getzy, **Then** the home screen shows tabs for All, Queued, and Finished with compact torrent rows, progress bars, status text, speed text, and per-row play or pause controls.
2. **Given** the user taps search, **When** they type a query, **Then** the list filters by torrent name without leaving the tab context.
3. **Given** the user taps Add torrent, **When** they paste a magnet URI, info hash, HTTP torrent URL, or local `.torrent` file, **Then** Getzy validates the input and adds it to the queue or shows a clear validation error.
4. **Given** active or paused torrents exist, **When** the user opens the overflow menu, **Then** they can resume all, pause all, modify queue order, open feeds, view session status, open settings, or shut down the engine.
5. **Given** RSS feeds are configured, **When** Getzy refreshes feeds, **Then** new feed items are shown and optional auto-download rules can add matched torrents.
6. **Given** network, storage, battery, VPN, or scheduling constraints are configured, **When** conditions change, **Then** the torrent engine enforces the constraints and the UI reflects the paused, blocked, active, or finished state.

### Edge Cases

- Invalid magnet URI, bad info hash, unsupported URL, or inaccessible `.torrent` file.
- Metadata fetch never completes or returns no files.
- Storage permission denied or selected folder unavailable.
- Device switches from Wi-Fi to mobile data while Wi-Fi-only mode is enabled.
- VPN disconnects while VPN-only mode is enabled.
- Battery level falls below configured limit.
- Engine crashes or Android kills the foreground service.
- Duplicate torrent is added by magnet, URL, RSS, or watched folder.
- RSS feed is unreachable, malformed, or contains duplicate items.

## Requirements

### Functional Requirements

- **FR-001**: Getzy MUST provide a Flutter Android app with dark theme, cyan accent, and compact list density matching the provided UI direction.
- **FR-002**: Getzy MUST support adding torrents from magnet links, info hashes, HTTP/HTTPS `.torrent` links, and local `.torrent` files.
- **FR-003**: Getzy MUST show torrent rows with name, status, progress percentage, downloaded/total size, download speed, upload speed, ETA when available, and a play/pause action.
- **FR-004**: Getzy MUST provide tabs for All, Queued, and Finished.
- **FR-005**: Getzy MUST provide in-list search by torrent name.
- **FR-006**: Getzy MUST provide sorting by queue number, name, date added, date finished, download speed, upload speed, and ETA.
- **FR-007**: Getzy MUST support resume all, pause all, queue modification, session status, settings, and shutdown actions.
- **FR-008**: Getzy MUST run active torrents through an Android foreground service with a persistent notification.
- **FR-009**: Getzy MUST persist torrent metadata, queue order, user settings, RSS feeds, session totals, and all-time transfer totals locally.
- **FR-010**: Getzy MUST expose settings for storage path, move-after-download, copy torrent files, watched incoming directory, bandwidth limits, connection limits, torrent protocol toggles, network ports, privacy/security, power management, scheduling, RSS feed refresh, advanced network interface, and about/legal screens.
- **FR-011**: Getzy MUST support RSS feed management with feed name, feed URL, manual refresh, configurable refresh interval, old-item cleanup, and optional automatic torrent downloads from a feed.
- **FR-012**: Getzy MUST provide session status with total transfer speeds, incoming connection status, torrent counts, session transfer totals, and all-time transfer totals.
- **FR-013**: Getzy MUST enforce Wi-Fi-only, VPN-only, charging-only, battery limit, scheduled start, and scheduled shutdown constraints before starting or resuming transfers.
- **FR-014**: Getzy MUST expose engine settings for DHT, LSD, UPnP, NAT-PMP, peer exchange, uTP, incoming/outgoing encryption, encryption level, proxy settings, and IP filtering.
- **FR-015**: Getzy MUST prevent duplicate torrents by comparing info hash after parsing or metadata resolution.
- **FR-016**: Getzy MUST show clear blocked states for permission, storage, network, VPN, battery, and engine errors.
- **FR-017**: Getzy MUST avoid built-in torrent search indexers, illegal content catalogs, ads, and analytics in v1.

### Non-Functional Requirements

- **NFR-001**: Home list scrolling SHOULD remain smooth with 500 persisted torrents.
- **NFR-002**: Search and sort updates SHOULD complete within 250 ms for 500 torrents on a mid-range Android device.
- **NFR-003**: UI state SHOULD recover within 3 seconds after engine service reconnection.
- **NFR-004**: Engine state changes SHOULD be delivered to UI at a configurable interval, defaulting to 1 second while visible.
- **NFR-005**: Tests MUST not download copyrighted or public internet content; use local fixtures, mocked engine adapters, and legal test torrents only.

## Key Entities

- **TorrentTask**: A user-managed torrent with info hash, name, files, trackers, progress, speeds, status, queue number, dates, and error state.
- **TorrentFile**: A file within a torrent with path, length, priority, progress, and selected flag.
- **EngineSession**: Runtime transfer state, totals, incoming port status, and engine lifecycle state.
- **AppSettings**: Storage, bandwidth, network, privacy, power, scheduling, feed, and advanced preferences.
- **RssFeed**: User-configured feed with name, URL, refresh status, cleanup rules, and auto-download flag.
- **RssItem**: Feed item with title, link, published date, dedupe key, and optional torrent source.
- **QueueRule**: Ordering and resume policy for queued torrents.

## UI Reference Mapping

- Home: dark toolbar, title `Getzy`, search, add-link icon, sort icon, overflow menu, tabs, compact torrent rows, floating `Add torrent` button.
- Search: top search field with keyboard focus and filtered list.
- Add magnet: centered dark dialog with large title, multiline input, Cancel and OK.
- Sort: centered dark dialog with selected cyan option and OK/Cancel.
- Menu: anchored dark overflow menu with Feeds, Resume all, Pause all, Modify queue, Session status, Settings, Shutdown.
- Feed manager: top bar with back, add, refresh, and add-feed dialog.
- Session status: metrics grouped by section dividers.
- Settings: category list for Storage, Bandwidth, Torrent, Interface, Network, Privacy & Security, Power management, Scheduling, Feeds, Advanced, About.
- Setting pages: large title, compact rows, cyan section headings, dividers, right-aligned switches where applicable.

## Success Criteria

- **SC-001**: A user can add a legal magnet link and see it move from metadata loading to queued/downloading/finished states.
- **SC-002**: A user can pause, resume, sort, search, and delete torrents without losing persisted state after app restart.
- **SC-003**: A user can configure Wi-Fi-only, VPN-only, storage path, speed limits, and RSS feeds, and Getzy enforces those settings.
- **SC-004**: Widget tests cover all primary screens and dialogs from the screenshot set.
- **SC-005**: Engine adapter contract tests prove UI logic works with mocked torrent events before native engine integration.

## Out of Scope for v1

- Built-in torrent index search across public piracy sites.
- Streaming media playback while downloading.
- Cloud sync.
- Desktop builds.
- Ads, paid ad-free tier, analytics, or crash-report telemetry.
