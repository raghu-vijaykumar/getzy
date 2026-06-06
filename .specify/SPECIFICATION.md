# Getzy Torrent Downloader Specification

**Status**: In Development (Phase 4)

## Summary
Getzy is a private, offline-first Android torrent downloader that gives users full control over downloads, bandwidth, and storage. No cloud sync, no telemetry, no tracking—just a local, efficient downloader optimized for Android.

## Problem Statement
Existing torrent clients are:
- Ad-supported or spyware-laden
- Cloud-connected with telemetry
- Bloated with features nobody uses
- Poorly optimized for battery and data usage
- Closed-source or unmaintained

Getzy solves this by providing a minimal, privacy-first torrent tool.

## User Stories & Features

### 1. Download Torrents Directly
**US1**: As a user, I can add torrents via magnet link, info hash, HTTP link, or torrent file.
- Dialog accepts all 4 formats
- Validates input before adding to queue
- Shows error for invalid sources

**US2**: As a user, I can manage my download queue (pause, resume, reorder, delete).
- Home screen shows All, Queued, and Finished tabs
- Each torrent shows progress, ETA, and speeds
- Overflow menu controls resume all / pause all / clear finished

**US3**: As a user, I can view torrent details (files, trackers, peers).
- Detail screen lists files with individual priority controls
- Shows torrent trackers and current peer count
- Delete with optional "also delete downloaded files" choice

### 2. RSS Feed Automation
**US4**: As a user, I can subscribe to RSS feeds and auto-download matching torrents.
- Feed manager: add, refresh, remove, show errors
- Optional regex filter per feed for selective downloads
- Auto-downloaded torrents appear in queue immediately

### 3. Settings & Constraints
**US5**: As a user, I can configure resource limits to respect device battery and data plan.
- Storage path and move-after-download destination
- Max download/upload speeds and connection limits
- Wi-Fi-only mode and battery limits (charging-only, battery %)
- Scheduled start and shutdown times

**US6**: As a user, I can enforce privacy and network constraints.
- Encryption enforcement
- IP filtering and UPnP/NAT-PMP toggle
- VPN-only mode (blocks all non-VPN transfers)
- Usage statistics disabled by default

### 4. Foreground Service & Notifications
**US7**: As a user, the app runs in the background without killing the download.
- Android foreground service with persistent notification
- Notification shows current speeds and pause/resume buttons
- App survives reboot and device sleep

## Design Principles

### Architecture
- **Engine Boundary**: Dart `TorrentEngine` interface abstracts native libtorrent
- **Repositories**: Separate persistence for torrents, feeds, settings, sessions
- **Event Streams**: Engine emits task/file updates; UI reacts
- **Fake Engine**: Local UI development without native code

### UI/UX
- Material 3, dark theme by default
- Compact torrent rows with progress bars
- Search and sort dialogs for large queues
- Clear action overflow menus instead of deep navigation
- All dialogs confirm before destructive actions

### Persistence
- SQLite schema: torrents, files, feeds, feed_items, queue_order, settings
- All data local; zero cloud sync
- Auto-migrations on app update

## Out of Scope (v1)
- Magnet link metadata preview
- Streaming playback
- Bittorrent extension protocols beyond core DHT/PEX
- Social discovery or community features
- Desktop apps (Android only for v1)

---

**Full detailed spec**: See `specs/001-getzy-torrent-downloader/spec.md`
