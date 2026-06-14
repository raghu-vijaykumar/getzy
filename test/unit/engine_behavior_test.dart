import 'package:flutter_test/flutter_test.dart';
import 'package:getzy/features/torrents/torrent_engine.dart';
import 'package:getzy/features/torrents/torrent_models.dart';

void main() {
  late TorrentEngine engine;

  setUp(() {
    engine = _TestEngine();
  });

  group('duplicate detection', () {
    test('rejects a duplicate info hash', () {
      engine.addTorrent('a' * 40);
      final result = engine.validateNewTorrentSource('a' * 40);
      expect(result, isNotNull);
      expect(result, contains('already'));
    });

    test('accepts a different info hash', () {
      engine.addTorrent('a' * 40);
      final result = engine.validateNewTorrentSource('b' * 40);
      expect(result, isNull);
    });
  });

  group('sorting', () {
    test('sorts by queue number by default', () {
      final torrents = engine.visibleTorrents(
        bucket: TorrentBucket.all,
        query: '',
      );
      for (var i = 1; i < torrents.length; i++) {
        expect(
          torrents[i].queueNumber,
          greaterThanOrEqualTo(torrents[i - 1].queueNumber),
        );
      }
    });

    test('sorts by name when selected', () async {
      await engine.updateSort(TorrentSortOption.name);
      final torrents = engine.visibleTorrents(
        bucket: TorrentBucket.all,
        query: '',
      );
      for (var i = 1; i < torrents.length; i++) {
        expect(
          torrents[i].name.toLowerCase(),
          greaterThanOrEqualTo(torrents[i - 1].name.toLowerCase()),
        );
      }
    });
  });

  group('filtering by bucket', () {
    test('TorrentBucket.all returns all torrents', () {
      final all = engine.visibleTorrents(bucket: TorrentBucket.all, query: '');
      expect(all.length, engine.torrents.length);
    });

    test('TorrentBucket.queued excludes finished torrents', () {
      final queued =
          engine.visibleTorrents(bucket: TorrentBucket.queued, query: '');
      expect(queued.every((t) => t.status != TorrentStatus.finished), isTrue);
    });

    test('TorrentBucket.finished returns only finished torrents', () {
      final finished =
          engine.visibleTorrents(bucket: TorrentBucket.finished, query: '');
      expect(finished.every((t) => t.status == TorrentStatus.finished), isTrue);
    });
  });

  group('filtering by query text', () {
    test('filters by name (case-insensitive)', () {
      final result = engine.visibleTorrents(
        bucket: TorrentBucket.all,
        query: 'ubuntu',
      );
      expect(result.every((t) => t.name.toLowerCase().contains('ubuntu')),
          isTrue);
    });

    test('returns empty list when nothing matches', () {
      final result = engine.visibleTorrents(
        bucket: TorrentBucket.all,
        query: 'zzzznothing',
      );
      expect(result, isEmpty);
    });

    test('returns all torrents with empty query', () {
      final result = engine.visibleTorrents(bucket: TorrentBucket.all, query: '');
      expect(result.length, engine.torrents.length);
    });
  });

  group('queue ordering', () {
    test('addTorrent assigns queue number 1 and bumps others', () async {
      await engine.addTorrent('a' * 40);
      await engine.addTorrent('b' * 40);
      final first = engine.torrents[0];
      final second = engine.torrents[1];
      expect(first.queueNumber, 1);
      expect(second.queueNumber, 2);
    });
  });
}

class _TestEngine extends TorrentEngine {
  final List<TorrentTask> _torrents = [];
  TorrentSortOption _sortOption = TorrentSortOption.queueNumber;
  final List<void Function()> _listeners = [];

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  @override
  List<TorrentTask> get torrents => List.unmodifiable(_torrents);

  @override
  TorrentSortOption get sortOption => _sortOption;

  @override
  bool get isShutdown => false;

  @override
  int get activeTorrentCount =>
      _torrents.where((t) => t.status.isRunning).length;

  @override
  int get finishedTorrentCount =>
      _torrents.where((t) => t.status == TorrentStatus.finished).length;

  @override
  int get downloadSpeedBytes =>
      _torrents.fold(0, (sum, t) => sum + t.downloadSpeedBytes);

  @override
  int get uploadSpeedBytes =>
      _torrents.fold(0, (sum, t) => sum + t.uploadSpeedBytes);

  @override
  TorrentEngineState get state => TorrentEngineState.running;

  @override
  Stream<TorrentEngineEvent> get events => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  String? validateNewTorrentSource(String source) {
    final normalized = source.trim().toLowerCase();
    if (_torrents.any((t) => t.infoHash == normalized)) {
      return 'This torrent is already in Getzy.';
    }
    return null;
  }

  @override
  Future<void> addTorrent(String source) async {
    final infoHash = source.trim().toLowerCase();
    if (_torrents.any((t) => t.infoHash == infoHash)) return;

    for (var i = 0; i < _torrents.length; i++) {
      _torrents[i] = _torrents[i].copyWith(
        queueNumber: _torrents[i].queueNumber + 1,
      );
    }

    _torrents.insert(0, TorrentTask(
      id: 'test-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Magnet ${infoHash.substring(0, 8).toUpperCase()}',
      infoHash: infoHash,
      queueNumber: 1,
      status: TorrentStatus.queued,
      progress: 0,
      downloadedBytes: 0,
      totalBytes: 1400 * 1024 * 1024,
      downloadSpeedBytes: 0,
      uploadSpeedBytes: 0,
      dateAdded: DateTime.now(),
    ));
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  Future<void> toggleTorrent(String id) async {}

  @override
  Future<void> resumeAll() async {}

  @override
  Future<void> pauseAll() async {}

  @override
  Future<void> shutdown() async {}

  @override
  Future<void> updateSort(TorrentSortOption option) async {
    _sortOption = option;
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  Future<void> reorderQueue(List<String> orderedTorrentIds) async {}

  @override
  Future<void> deleteTorrent(String id) async {}

  @override
  Future<void> triggerConstraintCheck() async {}

  @override
  void handleNotificationAction(String action) {}

  @override
  void setFilePriorities(String infoHash, List<TorrentFile> files) {}

  @override
  List<TorrentTask> visibleTorrents({
    required TorrentBucket bucket,
    required String query,
  }) {
    var filtered = _torrents.where((t) {
      if (bucket == TorrentBucket.queued) {
        return t.status != TorrentStatus.finished;
      }
      if (bucket == TorrentBucket.finished) {
        return t.status == TorrentStatus.finished;
      }
      return true;
    });

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((t) => t.name.toLowerCase().contains(q));
    }

    final sorted = filtered.toList();
    _sort(sorted);
    return sorted;
  }

  void _sort(List<TorrentTask> list) {
    list.sort((a, b) {
      switch (_sortOption) {
        case TorrentSortOption.queueNumber:
          return a.queueNumber.compareTo(b.queueNumber);
        case TorrentSortOption.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case TorrentSortOption.dateAdded:
          return b.dateAdded.compareTo(a.dateAdded);
        case TorrentSortOption.dateFinished:
          final aDate = a.dateFinished ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.dateFinished ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        case TorrentSortOption.downloadSpeed:
          return b.downloadSpeedBytes.compareTo(a.downloadSpeedBytes);
        case TorrentSortOption.uploadSpeed:
          return b.uploadSpeedBytes.compareTo(a.uploadSpeedBytes);
        case TorrentSortOption.eta:
          final aEta = a.eta ?? const Duration(days: 999);
          final bEta = b.eta ?? const Duration(days: 999);
          return aEta.compareTo(bEta);
      }
    });
  }
}
