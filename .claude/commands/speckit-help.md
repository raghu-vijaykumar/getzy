---
name: speckit-help
description: Quick reference for all Spec Kit commands
---

# Spec Kit Commands Reference

## Available Commands

| Command                 | Purpose                            |
| ----------------------- | ---------------------------------- |
| `/speckit-help`         | This guide                         |
| `/speckit-constitution` | Review project principles & vision |
| `/speckit-tasks`        | View task list and mark progress   |
| `/speckit-plan`         | Review architecture and phases     |
| `/speckit-workflow`     | Learn how to execute tasks         |
| `/speckit-implement`    | Start implementing a task          |

## Quick Start (3 Steps)

### 1. Understand the Project
```
/speckit-constitution  → Read principles
/speckit-plan         → Understand architecture
```

### 2. Pick a Task
```
/speckit-tasks        → See task list
Current: Phase 5 (Settings) → T025, T026, ...
```

### 3. Implement
```
/speckit-implement    → Start T025 (or other task)
```

## Key Files to Know

| File                                          | What It Contains            |
| --------------------------------------------- | --------------------------- |
| `.specify/CONSTITUTION.md`                    | Project vision & principles |
| `.specify/SPECIFICATION.md`                   | User stories & requirements |
| `.specify/PLAN.md`                            | Architecture overview       |
| `.specify/TASKS.md`                           | Task checklist (quick ref)  |
| `.specify/WORKFLOW.md`                        | How to execute tasks        |
| `.specify/README.md`                          | Getting started guide       |
| `specs/001-getzy-torrent-downloader/spec.md`  | Detailed requirements       |
| `specs/001-getzy-torrent-downloader/plan.md`  | Detailed architecture       |
| `specs/001-getzy-torrent-downloader/tasks.md` | Full task descriptions      |

## Workflow Summary

```
1. Read task  (/speckit-tasks)
        ↓
2. Create todo list  (manage_todo_list)
        ↓
3. Implement code  (follow CONSTITUTION)
        ↓
4. Validate  (flutter analyze, flutter test)
        ↓
5. Mark complete  (.specify/TASKS.md, /memories/repo/spec-progress.md)
        ↓
6. Next task (/speckit-tasks)
```

## Current Progress

- ✅ **Phases 1–4**: Foundation, domain models, engine, home UI (~40%)
- 🔄 **Phase 5**: Settings screens (T025–T032) — **ACTIVE**
- ⬜ **Phases 6–9**: Automation, constraints, testing, release

## Next Recommended Task

**T025**: Settings category list screen

- Build a settings screen with 6 category tiles + About
- Wire routing from home overflow menu
- Add tests for category rendering

## Get Started

```
/speckit-tasks      → See task list
/speckit-implement  → Start implementing
```

What would you like to do?
