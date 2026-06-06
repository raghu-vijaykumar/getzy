import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'torrent_engine.dart';
import 'torrent_models.dart';
import 'torrent_repository.dart';
import 'torrent_validators.dart';

class FakeTorrentEngine extends TorrentEngine {
  FakeTorrentEngine.seeded()
      : _torrents = _seedTorrents(),
        _state = TorrentEngineState.running,
        _eventController = StreamController<TorrentEngineEvent>.broadcast();

  final StreamController<TorrentEngineEvent> _eventController;
  final TorrentRepository _repository = TorrentRepository.instance;
  TorrentEngineState _state;
  List<TorrentTask> _torrents;
  TorrentSortOption _sortOption = TorrentSortOption.queueNumber;
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
      _torrents.where((torrent) => torrent.status.isRunning).length;

  @override
  int get finishedTorrentCount => _torrents
      .where((torrent) => torrent.status == TorrentStatus.finished)
      .length;

  @override
  int get downloadSpeedBytes =>
      _torrents.fold(0, (total, torrent) => total + torrent.downloadSpeedBytes);

  @override
  int get uploadSpeedBytes =>
      _torrents.fold(0, (total, torrent) => total + torrent.uploadSpeedBytes);

  @override
  Stream<TorrentEngineEvent> get events => _eventController.stream;

  @override
  Future<void> initialize() async {
    final persistedTorrents = await _repository.loadTorrents();
    if (persistedTorrents.isNotEmpty) {
      _torrents = persistedTorrents;
    } else {
      await _repository.saveTorrents(_torrents);
    }
    _state = TorrentEngineState.running;
    _emitEvent(TorrentEngineStateChanged(_state));
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
      filtered =
          filtered.where((torrent) => torrent.status != TorrentStatus.finished);
    } else if (bucket == TorrentBucket.finished) {
      filtered =
          filtered.where((torrent) => torrent.status == TorrentStatus.finished);
    }

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      filtered = filtered.where(
          (torrent) => torrent.name.toLowerCase().contains(normalizedQuery));
    }

    final sorted = filtered.toList();
    sorted.sort(_compareBySelectedSort);
    return sorted;
  }

  @override
  String? validateNewTorrentSource(String source) {
    final validationMessage = validateTorrentSource(source);
    if (validationMessage != null) {
      return validationMessage;
    }

    final normalized = source.trim();
    final infoHash = _extractInfoHash(normalized);
    if (_torrents.any((torrent) => torrent.infoHash == infoHash)) {
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
    final task = TorrentTask(
      id: 'torrent-${DateTime.now().microsecondsSinceEpoch}',
      name: _displayNameForSource(normalized, infoHash),
      infoHash: infoHash,
      queueNumber: 1,
      status: _isShutdown ? TorrentStatus.paused : TorrentStatus.queued,
      progress: 0,
      downloadedBytes: 0,
      totalBytes: 1400 * 1024 * 1024,
      downloadSpeedBytes: 0,
      uploadSpeedBytes: 0,
      dateAdded: DateTime.now(),
      eta: const Duration(hours: 2, minutes: 10),
    );

    _torrents = [
      task,
      ..._torrents.map(
        (torrent) => torrent.copyWith(queueNumber: torrent.queueNumber + 1),
      ),
    ];
    await _repository.saveTorrents(_torrents);
    notifyListeners();
    _emitEvent(TorrentTaskUpdated(task));
  }

  @override
  Future<void> toggleTorrent(String id) async {
    _isShutdown = false;
    TorrentTask? updated;
    _torrents = _torrents.map((torrent) {
      if (torrent.id != id || !torrent.status.canToggle) {
        return torrent;
      }

      final next = torrent.status.isRunning
          ? torrent.copyWith(
              status: TorrentStatus.paused,
              downloadSpeedBytes: 0,
              uploadSpeedBytes: 0,
            )
          : torrent.copyWith(
              status: TorrentStatus.downloading,
              downloadSpeedBytes: 420 * 1024,
              uploadSpeedBytes: 38 * 1024,
            );
      updated = next;
      return next;
    }).toList();
    await _repository.saveTorrents(_torrents);
    notifyListeners();
    if (updated != null) {
      _emitEvent(TorrentTaskUpdated(updated!));
    }
  }

  @override
  Future<void> resumeAll() async {
    _isShutdown = false;
    _torrents = _torrents.map((torrent) {
      if (torrent.status == TorrentStatus.finished ||
          torrent.status == TorrentStatus.blocked) {
        return torrent;
      }
      final updated = torrent.copyWith(
        status: TorrentStatus.downloading,
        downloadSpeedBytes: max(torrent.downloadSpeedBytes, 240 * 1024),
        uploadSpeedBytes: max(torrent.uploadSpeedBytes, 24 * 1024),
      );
      _emitEvent(TorrentTaskUpdated(updated));
      return updated;
    }).toList();
    await _repository.saveTorrents(_torrents);
    notifyListeners();
  }

  @override
  Future<void> pauseAll() async {
    _torrents = _torrents.map((torrent) {
      if (!torrent.status.canToggle) {
        return torrent;
      }
      final updated = torrent.copyWith(
        status: TorrentStatus.paused,
        downloadSpeedBytes: 0,
        uploadSpeedBytes: 0,
      );
      _emitEvent(TorrentTaskUpdated(updated));
      return updated;
    }).toList();
    await _repository.saveTorrents(_torrents);
    notifyListeners();
  }

  @override
  Future<void> shutdown() async {
    _isShutdown = true;
    _state = TorrentEngineState.shutdown;
    await pauseAll();
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
    final currentById = {for (final torrent in _torrents) torrent.id: torrent};
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
    await _repository.updateQueueOrder(_torrents.map((t) => t.id).toList());
    await _repository.saveTorrents(_torrents);
    notifyListeners();
  }

  @override
  Future<void> deleteTorrent(String id) async {
    _torrents.removeWhere((torrent) => torrent.id == id);
    await _repository.deleteTorrent(id);
    notifyListeners();
    _emitEvent(TorrentEngineStateChanged(_state));
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

  static String _extractInfoHash(String source) {
    final directHash =
        RegExp(r'^[a-f0-9]{40}$', caseSensitive: false).firstMatch(source);
    if (directHash != null) {
      return source.toLowerCase();
    }

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

    // URL adds are represented by a deterministic hash until the native engine resolves metadata.
    return source
        .toLowerCase()
        .hashCode
        .abs()
        .toRadixString(16)
        .padLeft(40, '0')
        .substring(0, 40);
  }

  static String _displayNameForSource(String source, String infoHash) {
    final lower = source.toLowerCase();
    if (lower.startsWith('http')) {
      final uri = Uri.tryParse(source);
      final segment = uri == null || uri.pathSegments.isEmpty
          ? 'Remote torrent'
          : uri.pathSegments.last;
      return segment.replaceAll('.torrent', '');
    }

    if (lower.endsWith('.torrent')) {
      final normalized = source.replaceAll('\\', '/');
      final segments = normalized.split('/');
      final fileName = segments.isNotEmpty ? segments.last : source;
      return fileName.replaceAll('.torrent', '');
    }

    return 'Magnet ${infoHash.substring(0, 8).toUpperCase()}';
  }

  static List<TorrentTask> _seedTorrents() {
    final now = DateTime.now();
    return [
      TorrentTask(
        id: 'ubuntu',
        name: 'Ubuntu Desktop 24.04 LTS',
        infoHash: '1111111111111111111111111111111111111111',
        queueNumber: 1,
        status: TorrentStatus.downloading,
        progress: 0.42,
        downloadedBytes: 2100 * 1024 * 1024,
        totalBytes: 5000 * 1024 * 1024,
        downloadSpeedBytes: 780 * 1024,
        uploadSpeedBytes: 32 * 1024,
        dateAdded: now.subtract(const Duration(hours: 3)),
        eta: const Duration(minutes: 18),
      ),
      TorrentTask(
        id: 'debian',
        name: 'Debian 12.5 netinst amd64',
        infoHash: '2222222222222222222222222222222222222222',
        queueNumber: 2,
        status: TorrentStatus.paused,
        progress: 0,
        downloadedBytes: 0,
        totalBytes: 690 * 1024 * 1024,
        downloadSpeedBytes: 0,
        uploadSpeedBytes: 0,
        dateAdded: now.subtract(const Duration(hours: 2, minutes: 15)),
        eta: const Duration(minutes: 42),
      ),
      TorrentTask(
        id: 'fedora',
        name: 'Fedora Workstation Live x86_64',
        infoHash: '3333333333333333333333333333333333333333',
        queueNumber: 3,
        status: TorrentStatus.queued,
        progress: 0,
        downloadedBytes: 0,
        totalBytes: 2200 * 1024 * 1024,
        downloadSpeedBytes: 0,
        uploadSpeedBytes: 0,
        dateAdded: now.subtract(const Duration(hours: 1, minutes: 50)),
        eta: const Duration(hours: 1, minutes: 5),
      ),
      TorrentTask(
        id: 'libreoffice',
        name: 'LibreOffice Fresh Offline Installers',
        infoHash: '4444444444444444444444444444444444444444',
        queueNumber: 4,
        status: TorrentStatus.finished,
        progress: 1,
        downloadedBytes: 920 * 1024 * 1024,
        totalBytes: 920 * 1024 * 1024,
        downloadSpeedBytes: 0,
        uploadSpeedBytes: 6 * 1024,
        dateAdded: now.subtract(const Duration(days: 1, hours: 4)),
        dateFinished: now.subtract(const Duration(hours: 10)),
      ),
      TorrentTask(
        id: 'archive',
        name: 'Public Domain Film Archive Sample',
        infoHash: '5555555555555555555555555555555555555555',
        queueNumber: 5,
        status: TorrentStatus.blocked,
        progress: 0.12,
        downloadedBytes: 180 * 1024 * 1024,
        totalBytes: 1500 * 1024 * 1024,
        downloadSpeedBytes: 0,
        uploadSpeedBytes: 0,
        dateAdded: now.subtract(const Duration(minutes: 52)),
        eta: const Duration(hours: 3),
        blockedReason: 'Storage permission needed',
      ),
    ];
  }
}
