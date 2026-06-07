# Feature Specification: Missing Functionality Completion

**Feature Branch**: `002-feature-completion`  
**Created**: 2026-06-07  
**Status**: Draft  
**Input**: User feedback after v1 test — torrent add flow doesn't fetch metadata or download, UI text scaling too large, no theme switching, most settings are UI-only with no functional wiring.

---

## Audit Summary

Of ~46 settings across 11 categories, only **3 are fully functional** (WiFi-only, VPN-only, Charging-only — all consumed by `ConstraintChecker`). **7 are partially wired** (persisted to DB but not consumed by any engine behavior). **36 are UI-only** — toggles that don't persist or don't affect behavior, and display-only rows.

Three major missing features were also reported:
1. Adding a torrent (magnet/info hash/URL/file) shows up in the list but **never fetches real metadata or downloads** — it's entirely synthetic.
2. All text sizes are hardcoded; there is no global font scaling control.
3. Theme is hardcoded to dark-only; no light or system theme option.

---

## Requirements

### FR-001: Real Metadata Fetch & Download for Added Torrents

**Problem**: `FakeTorrentEngine.addTorrent()` creates a synthetic `TorrentTask` with a fake name (`"Magnet XXXXXXXX"`), hardcoded size (1.4 GB), and fixed ETA (2h10m). No DHT/tracker resolution happens. The torrent appears in the list but never progresses past 0%.

**Requirements**:
1. When a magnet link or info hash is added, the engine MUST resolve metadata from DHT/trackers before creating a `TorrentTask`.
2. When an HTTP `.torrent` URL is added, the engine MUST download the `.torrent` file and parse its metadata (name, files, total size, piece count, trackers).
3. When a local `.torrent` file is added, the engine MUST parse the file for metadata.
4. After metadata is resolved, a **file selection dialog** MUST be shown listing all files in the torrent with their sizes, allowing the user to select/deselect individual files before download starts.
5. After file selection is confirmed, the engine MUST begin actual downloading (connecting to peers via DHT/trackers, requesting pieces, writing to disk).
6. The `FakeTorrentEngine` simulation path MUST still exist for testing — consider a `FakeTorrentEngine` vs `RealTorrentEngine` split, or an engine adapter that can be swapped.

**Implementation notes**:
- Flutter has no mature pure-Dart BitTorrent library. Options:
  - **Platform channel to native libtorrent** (recommended for Android) — requires adding a native plugin that links libtorrent.
  - **Pure Dart BitTorrent client** (high effort, high risk).
  - **Enhanced simulation** — make `FakeTorrentEngine` simulate metadata resolution (async delay, then realistic files), simulate download progress over time, and simulate completion. This is the pragmatic path for a demo/app that doesn't need to download real copyrighted content.
- The enhanced simulation path should:
  - Validate and parse real `.torrent` files (bencode parser) when a file or URL is provided.
  - For magnet links, generate a realistic file set based on the info hash (since we can't actually resolve DHT without a real engine).
  - Simulate progress with a timer-based increment.
  - Surface files in `TorrentTask.files` for the file selection UI.

---

### FR-002: File Selection Before Download

**Problem**: Currently when a torrent is added, it goes directly to the torrent list. Users have no way to see or select which files they want to download.

**Requirements**:
1. After metadata is resolved (or synthetic metadata is generated), show a **full-screen file selection dialog** or a **bottom sheet** listing all files with:
   - Checkbox per file (default: all selected)
   - File name/path within the torrent
   - File size formatted
   - Select all / deselect all toggle
2. Only files that are checked should be marked as selected in the `TorrentFile` model.
3. The engine MUST download only selected files (set file priorities to 0 for deselected files).
4. A "Start download" button begins the download; a "Cancel" button aborts the addition.

---

### FR-003: Theme Switching (Dark / Light / System)

**Problem**: `getzy_theme.dart` defines only a dark theme with `Brightness.dark` hardcoded. No light theme or system-follow mode exists. The Interface > Theme setting is a read-only label showing "Dark".

**Requirements**:
1. Define a complete **light theme** in addition to the existing dark theme:
   - Light background (e.g. `#FFFFFF` or `#F5F5F5`), dark text, adjusted accent/action/fab colors for contrast.
   - All theme customizations (dialogs, app bar, tabs, inputs, FAB, list tiles, dividers) MUST have light-mode equivalents.
2. Add a `themeMode` setting that supports three values:
   - `"dark"` — always use dark theme.
   - `"light"` — always use light theme.
   - `"system"` — follow `MediaQuery.platformBrightness` or `WidgetsBinding.instance.window.platformBrightness`.
3. Replace the Interface > Theme read-only row with a **tappable row** that opens a dialog with three radio options (Dark / Light / System). On selection:
   - Persist the choice to settings DB (key: `theme_mode`).
   - Rebuild the widget tree with the new `ThemeMode`.
4. `GetzyApp` MUST listen for theme changes (via `SettingsRepository` or a `ChangeNotifier`) and rebuild with the selected theme mode.

---

### FR-004: Global Text Size Slider

**Problem**: All text sizes are hardcoded absolute values (42pt headings, 22pt category titles, 20pt row labels, 16pt body, etc.). There is no way to adjust text size globally. Buttons and labels appear too large on some devices.

**Requirements**:
1. Add a `textScaleFactor` setting persisted to the settings DB (key: `text_scale_factor`), defaulting to `1.0`.
2. In the Interface settings section, add a **tappable row "Text size"** that opens a dialog with a `Slider` ranging from 0.7 to 1.5 (step 0.1), showing the current value as a percentage (e.g. "100%", "85%", "130%").
3. On change, persist the value and rebuild the app tree.
4. Wrap the MaterialApp in a `MediaQuery` that applies `MediaQuery.of(context).copyWith(textScaleFactor: <saved_value>)` so all text in the app scales uniformly.
5. The slider preview should show sample text at the selected size so the user can see the effect before confirming.

---

### FR-005: Storage Settings Functionality

**Problem**: Storage path is display-only, move-after-download is persisted but not consumed, copy torrent files and watch directory are UI-only.

**Requirements**:
1. **Storage path**: Replace the display-only row with a tappable row that opens a directory picker (using `file_picker` or a platform channel to SAF). Persist the chosen path (key: `storage_path`). Default: `/storage/emulated/0/Download/Getzy`.
2. **Move after download**: When enabled and a download completes, the engine MUST move the completed files from the storage path to the "move completed to location" path. The destination path row MUST become enabled when the switch is on, and be tappable to pick a directory.
3. **Copy torrent files**: When enabled, after metadata is resolved, save the `.torrent` file to the "copy torrent files to location" path. The destination row MUST become enabled when the switch is on.
4. **Watch incoming directory**: When enabled, use a platform channel or `dart:io` `FileSystemEntity.watch()` to monitor the directory. When a new `.torrent` file appears, automatically call `addTorrent()` with the file path. Persist the watched directory path. Show a directory picker for the path.

---

### FR-006: Bandwidth Settings Functionality

**Problem**: Download/upload speed limits and max connections are display-only rows.

**Requirements**:
1. **Maximum download speed**: Replace with a tappable row that opens a dialog with:
   - A numeric text field (in KB/s).
   - Preset buttons: Unlimited, 100 KB/s, 500 KB/s, 1 MB/s, 5 MB/s.
   - Persist via key `max_download_speed` (0 = unlimited).
   - The engine MUST throttle download speed to this limit.
2. **Maximum upload speed**: Same pattern as download (key: `max_upload_speed`).
3. **Maximum number of connections**: Tappable row that opens a dialog with a numeric field (key: `max_connections`, default 200). Engine MUST limit concurrent peer connections.

---

### FR-007: Torrent Settings Functionality

**Problem**: Queue new torrents, start after adding, sequential download — all UI-only toggles.

**Requirements**:
1. **Queue new torrents** (key: `queue_new_torrents`): When enabled, new torrents are added with status `queued` and do not start until the user manually starts them or they reach the front of the queue. When disabled, new torrents start immediately.
2. **Start torrents after adding** (key: `start_after_adding`): When disabled, newly added torrents are paused regardless of queue setting.
3. **Sequential download** (key: `sequential_download`): When enabled, the engine downloads pieces in sequential order (file-order) rather than rarest-first. Useful for media that can be played before download completes.

---

### FR-008: Network Protocol Settings Functionality

**Problem**: DHT, LSD, UPnP, NAT-PMP, PEX, uTP, random port — all UI-only toggles.

**Requirements**:
1. All protocol toggles MUST be persisted to settings DB (keys: `enable_dht`, `enable_lsd`, `enable_upnp`, `enable_nat_pmp`, `enable_pex`, `enable_utp`, `random_port`, `contact_all_trackers`).
2. The engine MUST respect these settings when establishing connections. On a real engine, these would be passed as session params. On the fake engine, the values should be stored and readable but have no real effect.
3. **Use random port**: When enabled, assign a random port from 49152-65535. When disabled, enable the "Set a port number" row and allow the user to enter a specific port (key: `listening_port`, default 55623).

---

### FR-009: Privacy & Security Settings Functionality

**Problem**: Incoming/outgoing encryption, proxy, IP filtering are UI-only.

**Requirements**:
1. **Encryption settings** (incoming, outgoing, encryption level):
   - Replace display-only rows with tappable rows that show current value and open selection dialogs.
   - Incoming/outgoing: Enabled / Disabled toggle (persist keys: `encryption_incoming`, `encryption_outgoing`).
   - Encryption level: Forced / Enabled / Disabled radio selection (key: `encryption_level`).
   - Engine MUST respect these in peer connections.
2. **Proxy settings**: Tappable row that opens a dialog with proxy type (None / SOCKS4 / SOCKS5 / HTTP/HTTPS), host, port, and optional credentials (keys: `proxy_type`, `proxy_host`, `proxy_port`, `proxy_username`, `proxy_password`).
3. **IP filtering**: When enabled, load an IP filter file from the specified path and apply it to block connections from blacklisted IPs (key: `enable_ip_filter`, `ip_filter_path`). The file picker should be enabled when the switch is on.

---

### FR-010: Power Management Settings Completion

**Problem**: Battery level limit is display-only (defaults to 25% with no UI to change). Shutdown/background/CPU-awake settings are persisted but not consumed.

**Requirements**:
1. **Battery level limit**: Replace display-only row with a tappable row that opens a slider dialog (5%–100%, step 5%). Persist value (key: `battery_level`). `ConstraintChecker` already reads this key (with fallback 25%) — ensure it reads the actual saved value.
2. **Shutdown when downloads complete**: When enabled and all torrents are finished, call `engine.shutdown()`. Implement detection logic: after each torrent completion, check if any active torrents remain.
3. **Keep running in background**: When enabled, the foreground service should run with `START_STICKY` and not stop itself when the last torrent finishes. On Android, this controls the service restart behavior.
4. **Keep CPU awake**: When enabled, acquire a `WakeLock` (via platform channel or a plugin like `wakelock_plus`) to prevent CPU sleep during downloads.

---

### FR-011: Scheduling Settings Completion

**Problem**: Scheduled start/shutdown times display "Disabled" with no way to set them. Run only once and Resume all are permanently disabled.

**Requirements**:
1. **Scheduled start time**: Tappable row that opens a **time picker dialog**. Persist the chosen time (key: `scheduled_start_time`, format: `"HH:mm"`). `TorrentScheduler` already reads this key — ensure it's wired to the time picker. Show "Disabled" when no time is set, or "HH:mm" when set. Add a "Clear schedule" option to reset.
2. **Scheduled shutdown time**: Same pattern (key: `scheduled_shutdown_time`).
3. **Run only once**: Enable this switch. When enabled, the scheduler runs the scheduled start only once (clear the schedule after triggering). Persist via key `run_once`.
4. **Resume all**: Enable this switch. When enabled, at the scheduled start time, call `engine.resumeAll()` regardless of which torrents are queued.

---

### FR-012: Feed Settings Functionality

**Problem**: Feed refresh interval display-only (hardcoded 60 minutes). Old items cleanup display-only (hardcoded 5 days).

**Requirements**:
1. **Feed refresh interval**: Tappable row that opens a dialog with preset intervals (15 min, 30 min, 1 hour, 2 hours, 6 hours, 12 hours, 24 hours, Manual) plus a custom numeric input. Persist value (key: `feed_refresh_interval_minutes`). The feed refresh timer in `FeedRepository` MUST use this value.
2. **Remove old items**: Tappable row that opens a dialog with preset cleanup periods (Never, 1 day, 3 days, 5 days, 7 days, 14 days, 30 days). Persist value (key: `feed_cleanup_days`, 0 = never). Implement the actual cleanup logic that removes feed items older than the threshold.

---

### FR-013: Network Interface Selection

**Problem**: Network interface dialog has no OK/Save button — only Cancel. Selection is lost on dialog close.

**Requirements**:
1. Add an "OK" button to the network interface dialog that persists the selected interface (key: `network_interface`, default `"Any interface"`).
2. The subtitle of the Network interface row MUST update to show the currently selected interface.
3. When a specific network interface is selected (not "Any interface"), the engine MUST bind to that interface for all peer connections.

---

### FR-014: About Screen Fixes

**Problem**: Legal and Privacy policy screens use hardcoded fallback text instead of loading the markdown files at `assets/texts/legal.md` and `assets/texts/privacy.md`.

**Requirements**:
1. Ensure `assets/texts/legal.md` and `assets/texts/privacy.md` are declared in `pubspec.yaml` as assets.
2. `AboutScreen` MUST load the markdown files using `rootBundle.loadString()`.
3. If the asset file fails to load, fall back to the existing hardcoded text.

---

## Success Criteria

- **SC-001**: Adding a magnet link shows a file selection dialog with parsed (or simulated) file metadata, then the torrent progresses through download states to completion.
- **SC-002**: Toggling between Dark / Light / System themes in Interface > Settings immediately updates the entire app UI.
- **SC-003**: Adjusting the text size slider in Interface > Settings scales all text in the app between 70% and 150%.
- **SC-004**: At least 20 of the 36 currently UI-only settings are wired to functional behavior (persisted and consumed by the engine or app).
- **SC-005**: All setting toggles persist across app restarts and the app restores the correct state on launch.
- **SC-006**: All existing 134 widget/integration tests continue to pass after changes. New tests cover the added functionality.

---

## Out of Scope for v2

- Real native libtorrent integration (deferred to v3 — v2 uses enhanced simulation).
- Streaming playback while downloading.
- Peer blocking / IP filter lists.
- DHT node bootstrapping.
- Web seed support.
- µTorrent/Mac/desktop builds.

---

## Implementation Plan

### Phase 1: Core UX (High Visibility)
1. Theme switching (FR-003) — light theme definition + theme mode selector + `GetzyApp` rebuild
2. Text size slider (FR-004) — slider dialog + `MediaQuery.textScaleFactor` wrapper
3. About screen fix (FR-014) — asset loading for legal/privacy

### Phase 2: Settings Wiring (Medium Effort)
4. Storage settings (FR-005) — directory pickers, move-on-complete, copy torrents, watch dir
5. Torrent settings (FR-007) — queue/start/sequential logic
6. Power management completion (FR-010) — battery slider, shutdown-when-complete, CPU wake, background
7. Scheduling completion (FR-011) — time pickers, run-once, resume-all
8. Feed settings (FR-012) — interval picker, cleanup logic
9. Network interface selection (FR-013) — OK button + persistence

### Phase 3: Engine Integration (Complex)
10. Metadata fetch & download (FR-001) — enhanced simulation with bencode parsing, timer progress
11. File selection dialog (FR-002) — full-screen file list with checkboxes
12. Bandwidth settings (FR-006) — speed limiters, connection count limit
13. Network protocol settings (FR-008) — DHT/LSD/UPnP/NAT-PMP/PEX/uTP toggles + port config
14. Privacy & Security settings (FR-009) — encryption, proxy, IP filter

---

## Key Technical Changes

- `getzy_theme.dart` — add `buildLightTheme()`, refactor `buildGetzyTheme()` to accept brightness param.
- `getzy_app.dart` — add `themeMode` state, listen to settings changes, wrap in custom `MediaQuery` for text scale.
- `FakeTorrentEngine` — add bencode parser for `.torrent` files, add progress simulation timer, add file list generation, support throttle/concurrency settings.
- `SettingRowData` — extend with new interactive types: `SettingRowType.slider`, `SettingRowType.numeric`, `SettingRowType.timePicker`, `SettingRowType.directoryPicker`, `SettingRowType.radioGroup`.
- `_SettingRowState` — handle new row types in `build()`.
- `settings_repository.dart` — no changes needed (generic key-value storage already works).
