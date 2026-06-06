---
name: speckit-workflow
description: How to execute spec tasks step-by-step
---

# Spec-Driven Development Workflow

**Location**: `.specify/WORKFLOW.md`

## 6-Step Task Execution Process

### 1️⃣ Read Task Details

Open `.specify/TASKS.md` or `specs/001-getzy-torrent-downloader/tasks.md`

**Example**: Looking at T025 (Settings category list):
- **Description**: Build settings screen with list of 6 categories + About
- **Input**: Spec, plan, and current codebase
- **Acceptance**: Screen renders category tiles, navigation works

### 2️⃣ Create Todo List

Use `manage_todo_list` tool to track subtasks:

```
- [ ] Scaffold settings_screen.dart with category list UI
- [ ] Wire routing: home → settings
- [ ] Add category tiles (Storage, Bandwidth, Torrent/Network, Privacy, Power, Scheduling, About)
- [ ] Test: category list renders correctly
```

**Mark subtasks complete** as you finish each one.

### 3️⃣ Implement Code

Write code following clean architecture:
- **UI Layer**: Flutter widgets, Material Design 3
- **Repository Layer**: Persistence, business logic
- **Engine Boundary**: Keep TorrentEngine interface clean
- **No Mixing**: UI doesn't access database directly

**Example file structure**:
```
lib/features/settings/
├── settings_screen.dart          (UI)
├── settings_category_item.dart   (UI widget)
├── settings_repository.dart      (persistence)
└── settings_models.dart          (domain)
```

### 4️⃣ Validate

Before marking complete:

```bash
# Check for Dart/Flutter issues
flutter analyze

# Run unit tests
flutter test

# Manual testing (optional for UI)
flutter run --debug
```

**All must pass** before marking complete.

### 5️⃣ Mark Complete

- ✅ Update `.specify/TASKS.md` — check off task
- ✅ Update `/memories/repo/spec-progress.md` — mark phase progress
- ✅ Optional: Add brief summary comment in code if complex

### 6️⃣ Move to Next Task

Review priority order from `/speckit-tasks`:
1. T025 (Settings category list)
2. T026–T031 (Settings subpages)
3. T014–T015 (Native engine)
4. T035 (Feed auto-download)
5. T042+ (Testing suite)

Repeat from Step 1.

## Useful Commands

```bash
# Analyze entire project
flutter analyze

# Run all tests
flutter test

# Build APK (debug)
flutter build apk --debug

# Clean build artifacts
flutter clean && flutter pub get

# Run specific test file
flutter test test/widget_test.dart
```

## Architecture Boundaries to Preserve

| Boundary       | Don't Break                                                          |
| -------------- | -------------------------------------------------------------------- |
| **Engine**     | UI must go through TorrentEngine interface, not native code directly |
| **Repository** | UI uses repositories for data, not direct database access            |
| **Models**     | Domain models stay in their feature folder                           |
| **Platform**   | Android-specific code stays behind MethodChannel                     |

## Progress Tracking

After each task:
1. `.specify/TASKS.md` — check [ ] to [x]
2. `/memories/repo/spec-progress.md` — update completion %
3. Run `/speckit-tasks` to see updated progress

## Next Steps

- Run `/speckit-tasks` to see current phase
- Pick a task (e.g., "Implement T025")
- Run `/speckit-implement`
- I'll create todo list and start coding

What task would you like to tackle first?
