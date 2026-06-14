import 'dart:async';
import 'dart:collection';

import 'torrent_engine.dart';
import 'torrent_models.dart';
import 'torrent_validators.dart';

class FakeTorrentEngine extends TorrentEngine {
  FakeTorrentEngine._();

  factory FakeTorrentEngine.seeded() {
    final engine = FakeTorrentEngine._();
    engine._torrents.addAll(_seedTorrents());
    engine._state = TorrentEngineState.running;
    return engine;
  }

  static List<TorrentTask> _seedTorrents() {
    final now = DateTime.now();
    return [
      TorrentTask(
        id: 'a1b2c3d4e5f6a7b8c9d0',
        name: 'Ubuntu Desktop 24.04 LTS',
        infoHash: 'a1b2c3d4e5f6a7b8c9d0a1b2c3d4e5f6a7b8c9d0',
        queueNumber: 1,
        status: TorrentStatus.downloading,
        progress: 0.65,
        downloadedBytes: 1409286144,
        totalBytes: 2147483648,
        downloadSpeedBytes: 2457600,
        uploadSpeedBytes: 819200,
        dateAdded: now.subtract(const Duration(hours: 2)),
        eta: const Duration(minutes: 5),
      ),
      TorrentTask(
        id: 'b2c3d4e5f6a7b8c9d0e1',
        name: 'Fedora Workstation Live x86_64',
        infoHash: 'b2c3d4e5f6a7b8c9d0e1b2c3d4e5f6a7b8c9d0e1',
        queueNumber: 2,
        status: TorrentStatus.paused,
        progress: 0.32,
        downloadedBytes: 687865856,
        totalBytes: 2147483648,
        downloadSpeedBytes: 0,
        uploadSpeedBytes: 102400,
        dateAdded: now.subtract(const Duration(hours: 5)),
        eta: null,
      ),
      TorrentTask(
        id: 'c3d4e5f6a7b8c9d0e1f2',
        name: 'Debian 12.5 netinst amd64',
        infoHash: 'c3d4e5f6a7b8c9d0e1f2c3d4e5f6a7b8c9d0e1f2',
        queueNumber: 3,
        status: TorrentStatus.queued,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 734003200,
        downloadSpeedBytes: 0,
        uploadSpeedBytes: 0,
        dateAdded: now.subtract(const Duration(hours: 8)),
        eta: null,
      ),
      TorrentTask(
        id: 'd4e5f6a7b8c9d0e1f2a3',
        name: 'LibreOffice Fresh Offline Installers',
        infoHash: 'd4e5f6a7b8c9d0e1f2a3d4e5f6a7b8c9d0e1f2a3',
        queueNumber: 4,
        status: TorrentStatus.finished,
        progress: 1.0,
        downloadedBytes: 419430400,
        totalBytes: 419430400,
        downloadSpeedBytes: 0,
        uploadSpeedBytes: 51200,
        dateAdded: now.subtract(const Duration(hours: 24)),
        dateFinished: now.subtract(const Duration(hours: 12)),
        eta: Duration.zero,
      ),
    ];
  }

  final List<TorrentTask> _torrents = [];
  final StreamController<TorrentEngineEvent> _eventController =
      StreamController<TorrentEngineEvent>.broadcast();
  TorrentSortOption _sortOption = TorrentSortOption.queueNumber;
  TorrentEngineState _state = TorrentEngineState.initializing;
  bool _isShutdown = false;

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
    _state = TorrentEngineState.running;
    _emitEvent(TorrentEngineStateChanged(_state));
    notifyListeners();
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

    final normalized = source.trim();
    final infoHash = _extractInfoHash(normalized);

    for (var i = 0; i < _torrents.length; i++) {
      _torrents[i] = _torrents[i].copyWith(
        queueNumber: _torrents[i].queueNumber + 1,
      );
    }

    final name = _deriveName(normalized);

    final task = TorrentTask(
      id: infoHash,
      name: name,
      infoHash: infoHash,
      queueNumber: 1,
      status: TorrentStatus.downloading,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: 1400 * 1024 * 1024,
      downloadSpeedBytes: 0,
      uploadSpeedBytes: 0,
      dateAdded: DateTime.now(),
    );
    _torrents.insert(0, task);
    _emitEvent(TorrentTaskUpdated(task));
    notifyListeners();
  }

  @override
  Future<void> toggleTorrent(String id) async {
    final index = _torrents.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final torrent = _torrents[index];
    if (!torrent.status.canToggle) return;

    final newStatus = torrent.status.isRunning
        ? TorrentStatus.paused
        : TorrentStatus.downloading;
    final updated = torrent.copyWith(
      status: newStatus,
      downloadSpeedBytes: newStatus == TorrentStatus.paused ? 0 : torrent.downloadSpeedBytes,
      uploadSpeedBytes: newStatus == TorrentStatus.paused ? 0 : torrent.uploadSpeedBytes,
    );
    _torrents[index] = updated;
    _emitEvent(TorrentTaskUpdated(updated));
    notifyListeners();
  }

  @override
  Future<void> resumeAll() async {
    _isShutdown = false;
    final updated = _torrents.map((t) {
      if (t.status.canToggle && !t.status.isRunning) {
        return t.copyWith(
          status: TorrentStatus.downloading,
          downloadSpeedBytes: t.downloadSpeedBytes > 0 ? t.downloadSpeedBytes : 102400,
          uploadSpeedBytes: t.uploadSpeedBytes > 0 ? t.uploadSpeedBytes : 51200,
        );
      }
      return t;
    }).toList();
    _torrents
      ..clear()
      ..addAll(updated);
    notifyListeners();
  }

  @override
  Future<void> pauseAll() async {
    final updated = _torrents.map((t) {
      if (t.status.isRunning) {
        return t.copyWith(
          status: TorrentStatus.paused,
          downloadSpeedBytes: 0,
          uploadSpeedBytes: 0,
        );
      }
      return t;
    }).toList();
    _torrents
      ..clear()
      ..addAll(updated);
    notifyListeners();
  }

  @override
  Future<void> shutdown() async {
    if (_isShutdown) return;
    _isShutdown = true;
    _state = TorrentEngineState.shutdown;
    final updated = _torrents.map((t) {
      if (t.status.isRunning) {
        return t.copyWith(
          status: TorrentStatus.paused,
          downloadSpeedBytes: 0,
          uploadSpeedBytes: 0,
        );
      }
      return t;
    }).toList();
    _torrents
      ..clear()
      ..addAll(updated);
    _eventController.close();
    _emitEvent(TorrentEngineStateChanged(_state));
    notifyListeners();
  }

  @override
  Future<void> updateSort(TorrentSortOption option) async {
    _sortOption = option;
    _emitEvent(TorrentEngineStateChanged(_state));
    notifyListeners();
  }

  @override
  Future<void> reorderQueue(List<String> orderedTorrentIds) async {
    final currentById = {for (final t in _torrents) t.id: t};
    final reordered = <TorrentTask>[];
    var nextPosition = 1;

    for (final id in orderedTorrentIds) {
      final torrent = currentById.remove(id);
      if (torrent != null) {
        reordered.add(torrent.copyWith(queueNumber: nextPosition++));
      }
    }

    for (final remaining in currentById.values) {
      reordered.add(remaining.copyWith(queueNumber: nextPosition++));
    }

    _torrents
      ..clear()
      ..addAll(reordered);
    notifyListeners();
  }

  @override
  Future<void> deleteTorrent(String id) async {
    _torrents.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  @override
  Future<void> triggerConstraintCheck() async {}

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

  @override
  void setFilePriorities(String infoHash, List<TorrentFile> files) {}

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
      filtered = filtered.where(
        (t) => t.name.toLowerCase().contains(normalizedQuery),
      );
    }

    final sorted = filtered.toList();
    sorted.sort(_compareBySelectedSort);
    return sorted;
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
            .compareTo(
                left.dateFinished ?? DateTime.fromMillisecondsSinceEpoch(0));
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
      return source
          .toLowerCase()
          .hashCode
          .abs()
          .toRadixString(16)
          .padLeft(40, '0')
          .substring(0, 40);
    }

    return source
        .toLowerCase()
        .hashCode
        .abs()
        .toRadixString(16)
        .padLeft(40, '0')
        .substring(0, 40);
  }

  String _deriveName(String source) {
    if (source.toLowerCase().endsWith('.torrent')) {
      final segments = source.split(RegExp(r'[/\\]'));
      final name = segments.last;
      return name.replaceAll(RegExp(r'\.torrent$', caseSensitive: false), '');
    }
    final infoHash = _extractInfoHash(source);
    return 'Magnet ${infoHash.substring(0, 8).toUpperCase()}';
  }

  void _emitEvent(TorrentEngineEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}
