---
name: speckit-implement
description: Execute a spec task with structured workflow
---

# Implement Spec Task

Which task would you like to implement? (e.g., T025, T026)

## Implementation Workflow

Once you pick a task, I will:

1. **Review task details** from spec/plan
2. **Create a todo list** with subtasks using `manage_todo_list`
3. **Implement code** following clean architecture (engine/repository/UI boundaries)
4. **Validate** with `flutter analyze` and `flutter test`
5. **Mark complete** in `.specify/TASKS.md` and progress tracking

## Example: T025 (Settings Category List)

Subtasks:
- [ ] Create settings_screen.dart with category list UI
- [ ] Wire routing to settings screen
- [ ] Add navigation back to home
- [ ] Add test for category list rendering

## Preparation

Before I start, have you:
- ✅ Read the task description in `.specify/TASKS.md`?
- ✅ Reviewed the spec in `specs/001-getzy-torrent-downloader/spec.md`?
- ✅ Checked the plan in `.specify/PLAN.md`?

Tell me which task to implement (e.g., "Implement T025") and I'll start with a structured todo list.
