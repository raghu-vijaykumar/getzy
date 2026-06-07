# Getzy v1.0.0 — Release Notes

## Overview

Getzy is a Flutter torrent downloader for Android. This is the initial release (v1.0.0).

## Features

- **Torrent management**: Add torrents via info hash, magnet link, HTTP/HTTPS URL, or local .torrent file
- **Home screen**: All, Queued, and Finished tabs with search bar and sort options
- **Torrent details**: View file list, progress, speeds, ETA, and per-file controls
- **Engine**: Fake torrent engine for local UI development; native engine adapter ready for Android
- **Settings**: 12 category screens covering storage, bandwidth, torrent/network, privacy & security, power management, scheduling, feeds, and advanced options
- **Power management**: Wi-Fi-only, charging-only, and battery-limit transfer blocking
- **Scheduling**: Scheduled start and shutdown times
- **Foreground service**: Notification with pause/resume/shutdown actions
- **RSS**: Feed management with auto-download support
- **Onboarding**: Legal-use disclaimer and privacy policy acceptance screen

## Build Information

- **Version**: 1.0.0+1
- **Package name**: com.getzy.getzy
- **Minimum Android SDK**: Flutter default (21+)
- **Target Android SDK**: 35 (Android 15)

## Known Limitations

1. **Native engine placeholder**: The Android native libtorrent bridge (T013–T016) is scaffolded but the real engine is not yet integrated. All functionality uses the `FakeTorrentEngine`.
2. **Golden tests** (T047): Not yet implemented — visual regression testing requires screenshot infrastructure setup.
3. **Integration tests** (T048–T049): Not yet implemented — require an Android device/emulator running the full app.
4. **Performance tests** (T050): Not yet implemented — require benchmark infrastructure for 500+ torrent row testing.
5. **Adaptive icon**: The app launcher icon uses a generated vector drawable; a designer-provided icon would improve appearance.
6. **Release signing**: The debug APK is unsigned. For Play Store distribution, configure release signing in `android/app/build.gradle`.
7. **Desktop support**: The app targets Android only. Windows and web builds are untested.

## Permissions

The Android app declares the following permissions:

- `INTERNET` — torrent data transfer
- `ACCESS_NETWORK_STATE` / `ACCESS_WIFI_STATE` — connectivity-based transfer blocking
- `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_DATA_SYNC` — background download service
- `POST_NOTIFICATIONS` — notification permission (Android 13+)
- `RECEIVE_BOOT_COMPLETED` — scheduled start after reboot
- `WAKE_LOCK` — keep CPU awake during transfers

## Testing

All 130 tests pass:

- 20 unit tests (validators, models, RSS parsing)
- 10 engine behavior tests
- 27 engine conformance tests
- 77 widget tests (home screen, settings, search, sort, dialogs, feeds, onboarding)

Run: `flutter test`
Analyze: `flutter analyze` (2 info-level issues only)
