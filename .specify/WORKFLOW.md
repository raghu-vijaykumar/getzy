# Getzy Spec-Driven Development Workflow

## Process

For each task (e.g., T025, T026):

1. **Read Task Details**
   - Open `.specify/TASKS.md` or `specs/001-getzy-torrent-downloader/tasks.md`
   - Review acceptance criteria from spec and plan

2. **Create Todo List**
   - Use `manage_todo_list` tool to track subtasks
   - Example: T025 (Settings category list) → subtasks: scaffold screen, wire routing, add test

3. **Implement**
   - Write code following architecture principles from CONSTITUTION
   - Keep engine/repository/UI boundaries clean
   - Update progress memory after each subtask

4. **Validate**
   - Run `flutter analyze` → must pass
   - Run `flutter test` → unit tests pass
   - Test manually on Android emulator if UI-heavy

5. **Mark Complete**
   - Update `.specify/TASKS.md` checkbox
   - Update `/memories/repo/spec-progress.md`
   - Create brief summary comment in code if complex

6. **Move to Next Task**
   - Review priority order above
   - Start task-specific subtask list

## Useful Commands

```bash
# Analyze for errors
flutter analyze

# Run tests
flutter test

# Build APK (debug)
flutter build apk --debug

# Clean build artifacts
flutter clean
```

## File Structure

```
.specify/
  ├─ CONSTITUTION.md   (project principles)
  ├─ SPECIFICATION.md  (requirements & user stories)
  ├─ PLAN.md          (architecture & implementation strategy)
  ├─ TASKS.md         (task checklist with references)
  ├─ WORKFLOW.md      (this file: how to execute tasks)
  └─ templates/       (agent command templates, if needed)

specs/001-getzy-torrent-downloader/
  ├─ spec.md          (detailed requirements)
  ├─ plan.md          (detailed architecture)
  ├─ tasks.md         (full task checklist)
  └─ test-plan.md     (testing strategy)

lib/
  ├─ main.dart
  ├─ app/
  │  ├─ getzy_app.dart
  │  ├─ getzy_theme.dart
  │  └─ router.dart
  └─ features/
     ├─ torrents/      (torrent engine, home, detail)
     ├─ feeds/         (feed manager, repository)
     ├─ settings/      (settings screens, repository)
     └─ session/       (session & status)
```

## Key Principles

- **One Task at a Time**: Use manage_todo_list; mark subtasks complete as you finish
- **Spec-Driven**: Always read spec before coding; implement exactly what's in the task
- **Clean Architecture**: Keep engine/UI/persistence separate; use repositories
- **Validate Before Moving On**: `flutter analyze`, test pass, manual testing
- **Update Progress**: Mark tasks complete immediately in TASKS.md and spec-progress.md

---

For details on any task, read the corresponding section in `specs/001-getzy-torrent-downloader/tasks.md`.
