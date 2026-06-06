# Testing Specification: Getzy Torrent Downloader

## Test Strategy

Getzy testing is layered so UI, domain logic, engine contracts, and Android platform behavior can be verified independently. Network-facing tests MUST use local fixtures, mocked adapters, or legal public-domain test torrents only.

## Unit Tests

- Validators: magnet URI, info hash, HTTP/HTTPS torrent URL, RSS URL, port, speed limit, storage path, proxy fields, and IP filter path.
- Formatters: byte sizes, transfer speeds, ETA, percentages, dates, and status labels.
- Torrent list logic: tab filtering, search filtering, sort options, queue ordering, duplicate detection, and status grouping.
- Settings logic: default values, toggles, dependent disabled states, scheduled values, and constraint priority.
- RSS logic: feed parsing, item dedupe, malformed feed errors, refresh interval decisions, cleanup old items, and auto-download eligibility.
- Session logic: transfer totals, incoming connection warning state, all-time counters, and engine lifecycle status.

## Widget Tests

- Home screen renders title `Getzy`, toolbar icons, tabs, torrent rows, progress bars, and floating `Add torrent` button.
- Search mode focuses input, displays filtered results, and exits back to normal toolbar.
- Add torrent dialog validates empty and invalid values, accepts valid magnet/info-hash/URL input, and calls controller.
- Sort dialog shows all sort options, highlights selected option in cyan, and updates list ordering.
- Overflow menu exposes Feeds, Resume all, Pause all, Modify queue, Session status, Settings, and Shutdown.
- Feed manager renders add and refresh actions; add-feed dialog validates name and RSS link.
- Session status renders speed, connection, torrent count, session data, and all-time data rows.
- Settings category list renders all categories from the screenshots.
- Each settings subpage renders expected rows, disabled dependent rows, and switches.
- Network interface dialog renders available interfaces and persists selected option.

## Golden Tests

Golden tests SHOULD lock the dark visual direction:

- Home with queued torrents.
- Home search mode.
- Add magnet dialog.
- Sort dialog.
- Overflow menu.
- Feed manager with add dialog.
- Session status.
- Settings category list.
- Storage, Network, Privacy & Security, Power Management, Scheduling, Feeds, Advanced, and About pages.

## Engine Contract Tests

All engine implementations MUST satisfy the same contract:

- Add torrent from magnet returns a pending task and emits metadata state.
- Add duplicate torrent reports duplicate without creating a second task.
- Pause/resume one torrent emits expected status transitions.
- Pause/resume all emits transitions for eligible torrents.
- Remove torrent stops transfer and updates persistence.
- Queue move changes queue numbers deterministically.
- Speed limit and connection settings are applied to the session.
- Shutdown stops active work and emits stopped lifecycle state.
- Engine reconnect replays current torrent and session state.
- Engine error events map to user-visible blocked or failed states.

## Android Integration Tests

- Foreground service starts when a transfer starts and stops or idles according to settings.
- Notification shows active transfer state and supports pause, resume, and shutdown actions.
- Storage permission denial blocks add/start with a recoverable error.
- Wi-Fi-only blocks transfers on mobile data and resumes when Wi-Fi returns.
- VPN-only blocks transfers when VPN is disconnected.
- Charging-only and battery-limit settings pause and resume according to battery state.
- Scheduled start and shutdown trigger at configured local device time.
- Platform channel reconnects after activity recreation.

## Performance Tests

- Load 500 persisted torrents and verify home renders without jank beyond the accepted threshold.
- Search 500 torrents and update results within 250 ms.
- Sort 500 torrents by each supported option within 250 ms.
- Stream engine updates for 100 active torrents without UI event backlog.

## Manual QA Scenarios

- Add legal magnet link, info hash, HTTP `.torrent`, and local `.torrent` file.
- Attempt invalid input and verify error copy.
- Pause/resume/delete torrents and restart app.
- Configure storage path and move-after-download behavior.
- Add RSS feed, refresh feed, enable auto-download, and verify dedupe.
- Open every settings category and verify layout matches the screenshot direction.
- Kill the app during active transfer and verify recovery.
- Confirm no analytics, ads, or built-in piracy search sources exist.
