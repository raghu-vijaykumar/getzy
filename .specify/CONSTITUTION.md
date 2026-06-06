# Getzy Constitution: Project Principles

## Our Vision
Build a private, offline-first Android torrent downloader that prioritizes user control, resource efficiency, and legal compliance.

## Development Principles

### 1. User Privacy & Control
- No cloud syncing, network access logging, or telemetry
- User owns all download data and settings locally
- Transparent networking: all traffic is via torrent protocol or RSS feeds
- User can revoke app permissions and continue using offline features

### 2. Resource Efficiency
- Respect device battery via configurable speed limits and scheduling
- Honor data plans with Wi-Fi-only and bandwidth throttling options
- Minimize RAM and storage footprint for older devices
- Background service runs only when needed

### 3. Technical Integrity
- Use established, battle-tested libraries (libtorrent for core engine)
- SQLite for local-only persistence with no cloud backup
- Platform channels for Android integration, not webviews
- Responsive UI that never blocks network operations

### 4. Legal & Ethical Use
- Clearly display terms of legal use in onboarding
- Privacy policy explains data collection (none) and retention
- Encourage licensed content download alongside open-source projects
- Do not distribute copyrighted content; app is tool-only

### 5. Quality & Testing
- Contract tests ensure torrent engine compliance
- Widget tests validate all UI flows
- Integration tests verify state persistence and recovery
- Golden tests enforce dark theme consistency

### 6. Code Quality
- Clean architecture: engine boundary, repository pattern, domain models
- Linting rules enforced in CI
- No tech debt acceptance; fix issues before adding features
- Clear separation: UI/BL/persistence/platform layers

## Development Workflow

**Phases**: Foundation → Domain Models → Engine Boundary → UI → Settings → Automation → Constraints → Testing → Release

**Per-Task Process**:
1. Read spec/plan/task details from `specs/001-getzy-torrent-downloader/`
2. Create/update code with clean architecture
3. Run `flutter analyze` and `flutter test` before marking complete
4. Update task checklist when done
5. Preserve engine/repository/UI boundaries

## Technology Stack

- **Language**: Dart/Flutter
- **UI**: Material Design 3, dark theme
- **Persistence**: SQLite (`sqflite`), file system
- **Networking**: `http`, `xml` for feeds; `MethodChannel` for native
- **Engine**: libtorrent (native Android), abstracted behind `TorrentEngine` interface
- **Testing**: `test`, `flutter_test`, golden tests, `test_fixtures`
- **Build**: `flutter build apk` with gradle

## Non-Goals

- Cloud backup or sync
- Magnet link preview before adding
- Bittorrent extension protocols (DHT, PEX)
- Streaming playback
- Social features or discovery
