---
name: speckit-constitution
description: Review project principles and governing guidelines
---

# Getzy Constitution: Project Principles

**Location**: `.specify/CONSTITUTION.md`

## Our Vision

Build a **private, offline-first Android torrent downloader** that prioritizes user control, resource efficiency, and legal compliance.

No cloud sync. No telemetry. No tracking.

## 6 Core Principles

### 1. 🔒 User Privacy & Control
- ❌ No cloud syncing or network logging
- ❌ No telemetry or usage tracking
- ✅ User owns all data locally
- ✅ Transparent: all traffic is via torrent protocol or RSS only
- ✅ User can revoke permissions and continue using offline features

### 2. ⚡ Resource Efficiency
- Battery-respectful: configurable speed limits & scheduling
- Data-plan-aware: Wi-Fi-only mode, bandwidth throttling
- Lean: minimize RAM/storage for older devices
- Smart background service: only runs when needed

### 3. 🔧 Technical Integrity
- Use battle-tested libraries (libtorrent for torrent engine)
- SQLite for local-only persistence
- Platform channels (not webviews) for Android integration
- Responsive UI: never block network operations

### 4. ⚖️ Legal & Ethical Use
- Display legal-use terms in onboarding
- Privacy policy: explain data collection (none) & retention
- Encourage licensed content download
- **Tool only**: do not distribute copyrighted content

### 5. ✅ Quality & Testing
- Contract tests ensure torrent engine compliance
- Widget tests validate all UI flows
- Integration tests verify persistence & recovery
- Golden tests enforce dark theme consistency

### 6. 📐 Code Quality
- Clean architecture: engine/repository/UI boundaries
- Linting enforced in CI
- No tech debt: fix issues before adding features
- Clear layer separation

## Development Workflow

**Process**:
1. Read spec/plan/task details from `specs/001-getzy-torrent-downloader/` or `.specify/`
2. Create code with clean architecture
3. Run `flutter analyze` + `flutter test` before completing
4. Update task checklist
5. Preserve architecture boundaries

**Tech Stack**:
- Dart/Flutter
- Material 3, dark theme
- SQLite (`sqflite`)
- `http`, `xml` for feeds
- libtorrent (Android native, via `MethodChannel`)
- `test`, `flutter_test`, golden tests

## Non-Goals (v1)

- ❌ Cloud backup or sync
- ❌ Magnet link metadata preview
- ❌ Advanced Bittorrent extension protocols
- ❌ Streaming playback
- ❌ Social features or community discovery
- ❌ Desktop apps (Android only for v1)

---

Use `/speckit-tasks` to see task progress or `/speckit-plan` to review the architecture.
