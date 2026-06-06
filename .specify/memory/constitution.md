# Getzy Constitution

## Core Principles

### I. Lawful Torrent Client
Getzy MUST be a general-purpose BitTorrent client for lawful content only. Product copy, onboarding, samples, and tests MUST avoid encouraging copyright infringement, scraping pirate indexes, or embedding illegal content sources.

### II. Mobile-First Native Experience
Getzy MUST prioritize Android-first Flutter UX with a dark, dense, utility-focused interface inspired by the provided screenshots: torrent tabs, compact rows, modal dialogs, settings categories, and high-contrast transfer status.

### III. Real Torrent Engine Boundaries
Torrent protocol behavior MUST live behind a dedicated engine adapter so Flutter UI, state management, tests, and platform services can be developed independently from the native BitTorrent implementation.

### IV. User-Controlled Network and Storage
Every download, upload, network, VPN, Wi-Fi, battery, storage, RSS, scheduling, and privacy behavior MUST be explicit, discoverable, and reversible by the user.

### V. Testable by Contract
Each feature MUST include acceptance criteria, unit/widget coverage, engine contract tests, and platform integration checks for permissions, background service behavior, storage, and network constraints.

## Technical Guardrails

- Flutter target: stable channel, Android first, with architecture kept portable for future desktop support.
- State management: Riverpod or equivalent dependency-injected state layer.
- Persistence: SQLite for torrents, RSS feeds, settings, transfer history, and queued actions.
- Torrent engine: native Android service wrapping libtorrent or a compatible library via FFI/platform channels.
- Background work: foreground service with visible notification while transfers are active.
- Privacy: no analytics, ads, trackers, or built-in torrent indexers in v1.

## Spec Kit Workflow

Use GitHub Spec Kit workflow for new work:

1. Speckit Constitution
2. Speckit Specify
3. Speckit Plan
4. Speckit Tasks
5. Speckit Implement

Optional quality steps SHOULD be used for high-risk areas:

- Speckit Clarify for engine, permissions, or store-policy uncertainty.
- Speckit Checklist before implementation starts.
- Speckit Analyze before release candidates.

## Code Change Documentation

Code changes SHOULD include concise comments where intent is not obvious, especially around engine boundaries, Android service lifecycle, permissions, and test doubles.

## Governance

This constitution is the source of truth for Getzy feature planning. Feature specs and plans MUST call out any deviation and explain why the deviation is necessary before implementation begins.
