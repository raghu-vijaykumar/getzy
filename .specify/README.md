# Getzy Spec-Driven Development Kit

This directory contains the specification, plan, and workflow for building Getzy, a private offline-first Android torrent downloader.

## Quick Start

1. **Review Project Principles**: [CONSTITUTION.md](CONSTITUTION.md)
2. **Understand Requirements**: [SPECIFICATION.md](SPECIFICATION.md)
3. **Learn Architecture**: [PLAN.md](PLAN.md)
4. **Execute Tasks**: [WORKFLOW.md](WORKFLOW.md) and [TASKS.md](TASKS.md)

## Current Status

**Phase 4: Home UI** – Mostly complete. Next: **Phase 5: Settings Screens** (T025–T032).

Completeness: ~40% (foundation + domain + engine + home UI)

## Key Files

| File                                 | Purpose                                         |
| ------------------------------------ | ----------------------------------------------- |
| [CONSTITUTION.md](CONSTITUTION.md)   | Project principles, vision, non-goals           |
| [SPECIFICATION.md](SPECIFICATION.md) | User stories, features, design principles       |
| [PLAN.md](PLAN.md)                   | Architecture diagram, phase breakdown, strategy |
| [TASKS.md](TASKS.md)                 | Actionable task checklist                       |
| [WORKFLOW.md](WORKFLOW.md)           | How to execute each task step-by-step           |

## Full References

For detailed requirements, design decisions, and testing strategy, see the full spec in `specs/001-getzy-torrent-downloader/`:
- `spec.md` – Detailed feature specs
- `plan.md` – Detailed architecture
- `test-plan.md` – Testing strategy per phase

## Development Commands

```bash
# Check for Dart/Flutter issues
flutter analyze

# Run unit tests
flutter test

# Build for Android (debug)
flutter build apk --debug

# Clean build cache
flutter clean && flutter pub get
```

## Next Steps

1. **Start T025**: Build settings category list screen
2. **Complete T026–T031**: Add settings subscreens
3. **Then T035**: Implement feed auto-download
4. **Then T042+**: Add test suite

---

**Workflow**: Use [WORKFLOW.md](WORKFLOW.md) to execute each task with proper tracking and validation.
