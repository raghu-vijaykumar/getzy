import 'dart:async';

import 'package:flutter/foundation.dart';

import '../settings/settings_repository.dart';

class TorrentScheduler extends ChangeNotifier {
  TorrentScheduler() : _settings = SettingsRepository.instance;

  final SettingsRepository _settings;

  Timer? _startTimer;
  Timer? _shutdownTimer;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  VoidCallback? onScheduledStart;
  VoidCallback? onScheduledShutdown;

  Future<void> initialize() async {
    try {
      await _scheduleFromSettings();
    } catch (_) {
      // Settings may not be available in all environments.
    }
    _isRunning = true;
  }

  Future<void> _scheduleFromSettings() async {
    _startTimer?.cancel();
    _shutdownTimer?.cancel();

    final startTimeRaw = await _settings.loadValue('scheduled_start_time');
    if (startTimeRaw != null && startTimeRaw.isNotEmpty) {
      final parts = startTimeRaw.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          _startTimer = Timer(_nextOccurrence(hour, minute), () {
            onScheduledStart?.call();
            _scheduleFromSettings();
          });
        }
      }
    }

    final shutdownTimeRaw = await _settings.loadValue('scheduled_shutdown_time');
    if (shutdownTimeRaw != null && shutdownTimeRaw.isNotEmpty) {
      final parts = shutdownTimeRaw.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          _shutdownTimer = Timer(_nextOccurrence(hour, minute), () {
            onScheduledShutdown?.call();
            _scheduleFromSettings();
          });
        }
      }
    }
  }

  Duration _nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next.difference(now);
  }

  Future<void> reload() async {
    await _scheduleFromSettings();
    notifyListeners();
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _shutdownTimer?.cancel();
    super.dispose();
  }
}
