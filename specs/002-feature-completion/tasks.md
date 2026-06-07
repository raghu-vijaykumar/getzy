# Tasks: 002-feature-completion

## Phase 1 — Core UX (DONE)

- [x] FR-003 Theme switching (light theme + dark/light/system toggle in Settings > Interface)
- [x] FR-004 Global text size slider in Settings > Interface
- [x] FR-014 About screen — load legal.md and privacy.md assets from text files

## Phase 2 — Settings Wiring (DONE)

- [x] FR-005 Storage settings — directory pickers + persistence
- [x] FR-007 Torrent settings — queue/start/sequential setting keys
- [x] FR-010 Power management — battery level slider
- [x] FR-011 Scheduling — time pickers, run-once, resume-all
- [x] FR-012 Feed settings — interval picker, cleanup picker
- [x] FR-013 Network interface — OK button + persistence
- [x] FR-006 Bandwidth — speed limit preset pickers, connections slider
- [x] FR-008 Network — DHT/LSD/UPnP/PEX/uTP/port setting keys
- [x] FR-009 Privacy — encryption preset pickers, proxy type, IP filter

## Phase 3 — Real Engine (libtorrent via JNI)

### Engine Build
- [ ] Build libtorrent for Android (arm64-v8a, armeabi-v7a, x86_64)
- [ ] Create JNI bridge C++ library (libtorrent_bridge.so)
- [ ] Add prebuilt .so files to android/app/src/main/jniLibs/

### Native Kotlin Plugin
- [ ] Create TorrentBridge.kt — JNI function declarations + session management
- [ ] Create TorrentEnginePlugin.kt — MethodChannel handler + EventChannel polling
- [ ] Update MainActivity.kt to register TorrentEnginePlugin
- [ ] Implement all 11 MethodChannel methods (add, toggle, pauseAll, resumeAll, shutdown, delete, settings, etc.)

### Dart RealTorrentEngine
- [ ] Create RealTorrentEngine class implementing TorrentEngine
- [ ] Implement EventChannel listener for native status updates
- [ ] Wire addTorrent through MethodChannel
- [ ] Wire toggle, resumeAll, pauseAll, shutdown, delete
- [ ] Wire sort, reorderQueue
- [ ] Wire settings propagation (send persisted settings on initialize)
- [ ] Handle MissingPluginException fallback to FakeTorrentEngine

### File Selection (FR-002)
- [ ] Create TorrentAwaitingFileSelection event type
- [ ] Create file_selection_screen.dart with file list + checkboxes
- [ ] Integrate into addTorrent flow (show after metadata resolution)
- [ ] Wire setFilePriorities method to native

### Power Management Consumption
- [ ] shutdown_when_complete: native engine checks after each completion
- [ ] keep_cpu_awake: Android WakeLock via PowerManager
- [ ] keep_running_background: foreground service START_STICKY

### Migration & Testing
- [ ] Add `useRealEngine` flag in GetzyApp with platform detection
- [ ] Engine conformance tests pass with RealTorrentEngine
- [ ] Full test suite passes (134+ tests)
- [ ] APK builds and real torrent downloads work
- [ ] Remove FakeTorrentEngine default, use real on supported platforms
