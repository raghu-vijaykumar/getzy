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
- [x] Build libtorrent for Android (arm64-v8a, armeabi-v7a, x86_64) — CMakeLists.txt configured, Gradle integration in place
- [x] Create JNI bridge C++ library (torrent_bridge.cpp) — full implementation with settings parsing, status polling, file priorities
- [x] Add prebuilt .so files to android/app/src/main/jniLibs/ — CMake builds via externalNativeBuild in build.gradle

### Native Kotlin Plugin
- [x] Create TorrentBridge.kt — JNI function declarations + session management
- [x] Create TorrentEnginePlugin.kt — MethodChannel handler + EventChannel polling
- [x] Update MainActivity.kt to register TorrentEnginePlugin
- [x] Implement all 11 MethodChannel methods (add, toggle, pauseAll, resumeAll, shutdown, delete, settings, etc.)

### Dart RealTorrentEngine
- [x] Create RealTorrentEngine class implementing TorrentEngine
- [x] Implement EventChannel listener for native status updates
- [x] Wire addTorrent through MethodChannel
- [x] Wire toggle, resumeAll, pauseAll, shutdown, delete
- [x] Wire sort, reorderQueue
- [x] Wire settings propagation (send persisted settings on initialize)
- [x] Throw UnsupportedError on non-Android platforms (no simulation fallback)

### File Selection (FR-002)
- [x] Create TorrentAwaitingFileSelection event type
- [x] Create file_selection_screen.dart with file list + checkboxes
- [x] Integrate into addTorrent flow (show after metadata resolution)
- [x] Wire setFilePriorities method to native

### Power Management Consumption
- [x] shutdown_when_complete: native engine checks after each completion
- [x] keep_cpu_awake: Android WakeLock via PowerManager
- [x] keep_running_background: foreground service START_STICKY

### Migration & Testing
- [x] Platform detection: use RealTorrentEngine on Android, throw UnsupportedError elsewhere
- [ ] Engine conformance tests pass with RealTorrentEngine (mock MethodChannel for unit tests)
- [ ] Full test suite passes (134+ tests)
- [x] APK builds with native libtorrent (86.5 MB debug APK; includes `libtorrent-rasterbar.so` + `libtorrent_bridge.so` for arm64-v8a, armeabi-v7a, x86_64)
