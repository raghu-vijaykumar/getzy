import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../settings/settings_repository.dart';
import 'constraint_checker.dart';
import 'torrent_engine.dart';
import 'torrent_engine_platform.dart';
import 'torrent_models.dart';
import 'torrent_repository.dart';
import 'torrent_scheduler.dart';
import 'torrent_validators.dart';

class RealTorrentEngine extends TorrentEngine {
  RealTorrentEngine() : _eventController = StreamController<TorrentEngineEvent>.broadcast() {
    if (!Platform.isAndroid) {
      throw UnsupportedError('RealTorrentEngine is only available on Android');
    }
  }

  static const MethodChannel _methodChannel = MethodChannel('getzy/torrent_engine');
  static const EventChannel _eventChannel = EventChannel('getzy/torrent_engine_status');

  final StreamController<TorrentEngineEvent> _eventController;
  final TorrentRepository _repository = TorrentRepository.instance;
  final SettingsRepository _settingsRepo = SettingsRepository.instance;
  final ConstraintChecker _constraintChecker = ConstraintChecker();
  final TorrentScheduler _scheduler = TorrentScheduler();

  List<TorrentTask> _torrents = [];
  TorrentSortOption _sortOption = TorrentSortOption.queueNumber;
  TorrentEngineState _state = TorrentEngineState.initializing;
  bool _isShutdown = false;
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<List<ConstraintViolation>>? _constraintSub;

  @override
  UnmodifiableListView<TorrentTask> get torrents =>
      UnmodifiableListView(_torrents);

  @override
  TorrentSortOption get sortOption => _sortOption;

  @override
  bool get isShutdown => _isShutdown;

  @override
  TorrentEngineState get state => _state;

  @override
  int get activeTorrentCount =>
      _torrents.where((t) => t.status.isRunning).length;

  @override
  int get finishedTorrentCount =>
      _torrents.where((t) => t.status == TorrentStatus.finished).length;

  @override
  int get downloadSpeedBytes =>
      _torrents.fold(0, (total, t) => total + t.downloadSpeedBytes);

  @override
  int get uploadSpeedBytes =>
      _torrents.fold(0, (total, t) => total + t.uploadSpeedBytes);

  @override
  Stream<TorrentEngineEvent> get events => _eventController.stream;

  @override
  Future<void> initialize() async {
    try {
      final initialized = await _methodChannel.invokeMethod<bool>('initialize') ?? false;
      if (!initialized) {
        _state = TorrentEngineState.crashed;
        _emitEvent(TorrentEngineStateChanged(_state));
        notifyListeners();
        return;
      }

      await _propagateSettings();

      final persistedTorrents = await _repository.loadTorrents();
      _torrents = persistedTorrents;

      _statusSub = _eventChannel.receiveBroadcastStream().listen(
        _onStatusUpdate,
        onError: (_) {},
      );
    } catch (_) {
      _state = TorrentEngineState.crashed;
      _emitEvent(TorrentEngineStateChanged(_state));
      notifyListeners();
      return;
    }

    _updateNotification();

    try {
      await _constraintChecker.initialize();
    } catch (_) {}
    try {
      await _scheduler.initialize();
    } catch (_) {}
    _scheduler.onScheduledStart = () => resumeAll();
    _scheduler.onScheduledShutdown = () => shutdown();
    _constraintSub = _constraintChecker.violations.listen(_onConstraintsChanged);

    await _applyConstraints();
    await _updatePowerManagement();

    _state = TorrentEngineState.running;
    _emitEvent(TorrentEngineStateChanged(_state));
    notifyListeners();
  }

  Future<void> _updatePowerManagement() async {
    try {
      final keepAwake = await _settingsRepo.loadValue('keep_cpu_awake');
      if (keepAwake == 'true') {
        await _methodChannel.invokeMethod<void>('acquireWakeLock');
      } else {
        await _methodChannel.invokeMethod<void>('releaseWakeLock');
      }
    } catch (_) {}
  }

  Future<void> _propagateSettings() async {
    try {
      final keys = [
        'max_download_speed', 'max_upload_speed', 'max_connections',
        'enable_dht', 'enable_lsd', 'enable_upnp', 'enable_nat_pmp', 'enable_pex', 'enable_utp',
        'random_port', 'listening_port',
        'encryption_level', 'encryption_incoming', 'encryption_outgoing',
        'proxy_type', 'proxy_host', 'proxy_port', 'proxy_username', 'proxy_password',
      ];
      final settings = <String, String>{};
      for (final key in keys) {
        final value = await _settingsRepo.loadValue(key);
        if (value != null) settings[key] = value;
      }
      if (settings.isNotEmpty) {
        await _methodChannel.invokeMethod<void>('applySettings', settings);
      }
    } catch (_) {}
  }

  Future<void> applySavePath(String path) async {
    try {
      await _methodChannel.invokeMethod<void>('applySettings', {'storage_path': path});
    } catch (_) {}
  }

  void _onStatusUpdate(dynamic data) {
    if (data is! String) return;
    try {
      final List<dynamic> statuses = jsonDecode(data) as List<dynamic>;
      final now = DateTime.now();
      final existingById = {for (final t in _torrents) t.infoHash: t};
      var anyFinished = false;

      for (final s in statuses) {
        final map = s as Map<String, dynamic>;

        final eventType = map['event_type'] as String?;
        if (eventType == 'awaiting_file_selection') {
          final infoHash = map['info_hash'] as String? ?? '';
          final filesRaw = map['files'] as List<dynamic>? ?? [];
          final files = filesRaw.map((f) {
            final fmap = f as Map<String, dynamic>;
            return TorrentFile(
              path: fmap['path'] as String? ?? '',
              lengthBytes: (fmap['length'] as num?)?.toInt() ?? 0,
              priority: TorrentFilePriority.normal,
              progress: 0.0,
              selected: true,
            );
          }).toList();
          _emitEvent(TorrentAwaitingFileSelection(infoHash, files));
          continue;
        }

        final infoHash = map['info_hash'] as String? ?? '';
        if (infoHash.isEmpty) continue;

        final statusStr = map['status'] as String? ?? 'unknown';
        final progress = (map['progress'] as num?)?.toDouble() ?? 0.0;
        final downloaded = (map['downloaded_bytes'] as num?)?.toInt() ?? 0;
        final total = (map['total_bytes'] as num?)?.toInt() ?? 0;
        final dlSpeed = (map['download_speed'] as num?)?.toInt() ?? 0;
        final ulSpeed = (map['upload_speed'] as num?)?.toInt() ?? 0;
        final etaSecs = (map['eta'] as num?)?.toInt();
        final queuePosition = (map['queue_position'] as num?)?.toInt() ?? 0;

        final status = _parseTorrentStatus(statusStr);
        final existing = existingById[infoHash];

        final TorrentTask updated;
        if (existing != null) {
          updated = existing.copyWith(
            name: map['name'] as String? ?? existing.name,
            status: status,
            progress: progress,
            downloadedBytes: downloaded,
            totalBytes: total > 0 ? total : existing.totalBytes,
            downloadSpeedBytes: dlSpeed,
            uploadSpeedBytes: ulSpeed,
            eta: etaSecs != null ? Duration(seconds: etaSecs) : existing.eta,
            queueNumber: queuePosition > 0 ? queuePosition : existing.queueNumber,
            dateFinished: status == TorrentStatus.finished ? now : existing.dateFinished,
          );
          _torrents = _torrents.map((t) => t.id == updated.id ? updated : t).toList();
          if (status == TorrentStatus.finished && existing.status != TorrentStatus.finished) {
            anyFinished = true;
          }
        } else {
          final task = TorrentTask(
            id: infoHash,
            name: map['name'] as String? ?? 'Torrent $infoHash',
            infoHash: infoHash,
            queueNumber: queuePosition > 0 ? queuePosition : _torrents.length + 1,
            status: status,
            progress: progress,
            downloadedBytes: downloaded,
            totalBytes: total,
            downloadSpeedBytes: dlSpeed,
            uploadSpeedBytes: ulSpeed,
            dateAdded: now,
            eta: etaSecs != null ? Duration(seconds: etaSecs) : null,
          );
          _torrents = [..._torrents, task];
          try {
            _repository.saveTorrent(task);
          } catch (_) {}
        }
      }

      if (anyFinished) {
        _checkShutdownWhenComplete();
      }

      _updateNotification();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _checkShutdownWhenComplete() async {
    try {
      final enabled = await _settingsRepo.loadValue('shutdown_when_complete');
      if (enabled == 'true') {
        final hasActive = _torrents.any(
          (t) => t.status.isRunning || t.status == TorrentStatus.queued,
        );
        if (!hasActive) {
          shutdown();
        }
      }
    } catch (_) {}
  }

  TorrentStatus _parseTorrentStatus(String status) {
    switch (status) {
      case 'downloading':
        return TorrentStatus.downloading;
      case 'seeding':
        return TorrentStatus.finished;
      case 'finished':
        return TorrentStatus.finished;
      case 'paused':
        return TorrentStatus.paused;
      case 'checking':
        return TorrentStatus.checking;
      case 'queued':
        return TorrentStatus.queued;
      default:
        return TorrentStatus.queued;
    }
  }

  Future<void> _onConstraintsChanged(List<ConstraintViolation> violations) async {
    await _applyConstraints();
  }

  Future<void> _applyConstraints() async {
    final violations = _constraintChecker.currentViolations;
    if (violations.isEmpty) {
      _torrents = _torrents.map((torrent) {
        if (torrent.status == TorrentStatus.blocked) {
          final updated = torrent.copyWith(
            status: TorrentStatus.paused,
            blockedReason: null,
          );
          _emitEvent(TorrentTaskUpdated(updated));
          return updated;
        }
        return torrent;
      }).toList();
    } else {
      final reason = violations.map((v) => v.message).join('; ');
      _torrents = _torrents.map((torrent) {
        if (torrent.status.isRunning || torrent.status == TorrentStatus.queued) {
          _methodChannel.invokeMethod('toggleTorrent', {'id': torrent.infoHash});
          final updated = torrent.copyWith(
            status: TorrentStatus.blocked,
            blockedReason: reason,
            downloadSpeedBytes: 0,
            uploadSpeedBytes: 0,
          );
          _emitEvent(TorrentTaskUpdated(updated));
          return updated;
        }
        return torrent;
      }).toList();
    }
    try {
      await _repository.saveTorrents(_torrents);
    } catch (_) {}
    _updateNotification();
    notifyListeners();
  }

  void _emitEvent(TorrentEngineEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  @override
  List<TorrentTask> visibleTorrents({
    required TorrentBucket bucket,
    required String query,
  }) {
    Iterable<TorrentTask> filtered = _torrents;
    if (bucket == TorrentBucket.queued) {
      filtered = filtered.where((t) => t.status != TorrentStatus.finished);
    } else if (bucket == TorrentBucket.finished) {
      filtered = filtered.where((t) => t.status == TorrentStatus.finished);
    }

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      filtered = filtered.where((t) => t.name.toLowerCase().contains(normalizedQuery));
    }

    final sorted = filtered.toList();
    sorted.sort(_compareBySelectedSort);
    return sorted;
  }

  @override
  String? validateNewTorrentSource(String source) {
    final validationMessage = validateTorrentSource(source);
    if (validationMessage != null) return validationMessage;

    final normalized = source.trim();
    final infoHash = _extractInfoHash(normalized);
    if (_torrents.any((t) => t.infoHash == infoHash)) {
      return 'This torrent is already in Getzy.';
    }

    return null;
  }

  @override
  Future<void> addTorrent(String source) async {
    final validationError = validateNewTorrentSource(source);
    if (validationError != null) {
      throw TorrentInputException(validationError);
    }

    try {
      final infoHash = await _methodChannel.invokeMethod<String>('addTorrent', {
        'source': source.trim(),
      });
      if (infoHash == null || infoHash.isEmpty) {
        throw TorrentInputException('Failed to add torrent.');
      }
    } on MissingPluginException {
      throw TorrentInputException('Native engine is not available.');
    }
  }

  @override
  Future<void> toggleTorrent(String id) async {
    _isShutdown = false;
    try {
      await _methodChannel.invokeMethod<void>('toggleTorrent', {'id': id});
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> resumeAll() async {
    _isShutdown = false;
    try {
      await _methodChannel.invokeMethod<void>('resumeAll');
    } on MissingPluginException {}
  }

  @override
  Future<void> pauseAll() async {
    try {
      await _methodChannel.invokeMethod<void>('pauseAll');
    } on MissingPluginException {}
  }

  @override
  Future<void> shutdown() async {
    if (_isShutdown) return;
    _isShutdown = true;
    _state = TorrentEngineState.shutdown;
    try {
      await _methodChannel.invokeMethod<void>('releaseWakeLock');
    } catch (_) {}
    try {
      await _methodChannel.invokeMethod<void>('shutdown');
    } on MissingPluginException {}
    await _statusSub?.cancel();
    await _constraintSub?.cancel();
    await _constraintChecker.dispose();
    _scheduler.dispose();
    _emitEvent(TorrentEngineStateChanged(_state));
  }

  @override
  Future<void> updateSort(TorrentSortOption option) async {
    _sortOption = option;
    notifyListeners();
    _emitEvent(TorrentEngineStateChanged(_state));
  }

  @override
  Future<void> reorderQueue(List<String> orderedTorrentIds) async {
    final currentById = {for (final t in _torrents) t.id: t};
    final reordered = <TorrentTask>[];
    var nextPosition = 1;

    for (final id in orderedTorrentIds) {
      final torrent = currentById.remove(id);
      if (torrent != null) {
        final updated = torrent.copyWith(queueNumber: nextPosition++);
        reordered.add(updated);
        _emitEvent(TorrentTaskUpdated(updated));
      }
    }

    for (final remaining in currentById.values) {
      final updated = remaining.copyWith(queueNumber: nextPosition++);
      reordered.add(updated);
      _emitEvent(TorrentTaskUpdated(updated));
    }

    _torrents = reordered;
    try {
      await _repository.updateQueueOrder(_torrents.map((t) => t.id).toList());
      await _repository.saveTorrents(_torrents);
    } catch (_) {}
    _updateNotification();
    notifyListeners();
  }

  @override
  void handleNotificationAction(String action) {
    switch (action) {
      case 'pause_all':
        pauseAll();
        break;
      case 'resume_all':
        resumeAll();
        break;
      case 'shutdown':
        shutdown();
        break;
    }
  }

  void _updateNotification() {
    try {
      TorrentEnginePlatform.updateNotification(
        torrentCount: _torrents.length,
        activeCount: _torrents.where((t) => t.status.isRunning).length,
        downloadSpeed: formatSpeed(downloadSpeedBytes),
        uploadSpeed: formatSpeed(uploadSpeedBytes),
      );
    } catch (_) {}
  }

  @override
  Future<void> triggerConstraintCheck() async {
    await _constraintChecker.triggerCheck();
  }

  @override
  Future<void> deleteTorrent(String id) async {
    try {
      await _methodChannel.invokeMethod<void>('deleteTorrent', {'id': id});
    } on MissingPluginException {}
    _torrents.removeWhere((t) => t.id == id);
    try {
      await _repository.deleteTorrent(id);
    } catch (_) {}
    _updateNotification();
    notifyListeners();
    _emitEvent(TorrentEngineStateChanged(_state));
  }

  @override
  void setFilePriorities(String infoHash, List<TorrentFile> files) {
    final selected = files.where((f) => f.selected).toList();
    try {
      _methodChannel.invokeMethod<void>('setFilePriorities', {
        'info_hash': infoHash,
        'selected_files': selected.map((f) => f.path).toList(),
      });
    } on MissingPluginException {}
  }

  int _compareBySelectedSort(TorrentTask left, TorrentTask right) {
    switch (_sortOption) {
      case TorrentSortOption.queueNumber:
        return left.queueNumber.compareTo(right.queueNumber);
      case TorrentSortOption.name:
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      case TorrentSortOption.dateAdded:
        return right.dateAdded.compareTo(left.dateAdded);
      case TorrentSortOption.dateFinished:
        return (right.dateFinished ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(left.dateFinished ?? DateTime.fromMillisecondsSinceEpoch(0));
      case TorrentSortOption.downloadSpeed:
        return right.downloadSpeedBytes.compareTo(left.downloadSpeedBytes);
      case TorrentSortOption.uploadSpeed:
        return right.uploadSpeedBytes.compareTo(left.uploadSpeedBytes);
      case TorrentSortOption.eta:
        return (left.eta ?? const Duration(days: 999))
            .compareTo(right.eta ?? const Duration(days: 999));
    }
  }

  String _extractInfoHash(String source) {
    final directHash =
        RegExp(r'^[a-f0-9]{40}$', caseSensitive: false).firstMatch(source);
    if (directHash != null) return source.toLowerCase();

    final magnetHash = RegExp(r'btih:([a-z0-9]{32,40})', caseSensitive: false)
        .firstMatch(source);
    if (magnetHash != null) {
      return magnetHash
          .group(1)!
          .toLowerCase()
          .padRight(40, '0')
          .substring(0, 40);
    }

    if (source.toLowerCase().endsWith('.torrent')) {
      return source.toLowerCase().hashCode.abs().toRadixString(16).padLeft(40, '0').substring(0, 40);
    }

    return source.toLowerCase().hashCode.abs().toRadixString(16).padLeft(40, '0').substring(0, 40);
  }

  @override
  void dispose() {
    if (!_isShutdown) {
      shutdown();
    }
    _eventController.close();
    super.dispose();
  }
}
