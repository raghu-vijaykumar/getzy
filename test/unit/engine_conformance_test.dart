import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getzy/features/torrents/fake_torrent_engine.dart';
import 'package:getzy/features/torrents/torrent_engine.dart';
import 'package:getzy/features/torrents/torrent_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTorrentEngine engine;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '${Directory.systemTemp.path}/getzy_test';
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('getzy/torrent_engine'),
      (MethodCall methodCall) async {
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/charging'),
      (MethodCall methodCall) async => null,
    );
  });

  setUp(() {
    engine = FakeTorrentEngine.seeded();
  });

  tearDown(() {
    engine.shutdown();
  });

  group('TorrentEngine conformance', () {
    test('starts in running state for seeded engine', () async {
      expect(engine.state, TorrentEngineState.running);
    });

    test('initialize transitions to running state', () async {
      await engine.initialize();
      expect(engine.state, TorrentEngineState.running);
    });

    test('returns seeded torrents after initialize', () async {
      await engine.initialize();
      expect(engine.torrents.length, greaterThan(0));
    });

    test('emits state change event on initialize', () async {
      final eventFuture =
          engine.events.firstWhere((e) => e is TorrentEngineStateChanged);
      await engine.initialize();
      final event = await eventFuture;
      expect(event, isA<TorrentEngineStateChanged>());
    });

    test('addTorrent adds a torrent to the list', () async {
      await engine.initialize();
      final before = engine.torrents.length;
      await engine.addTorrent('a' * 40);
      expect(engine.torrents.length, before + 1);
    });

    test('addTorrent rejects duplicate info hashes', () async {
      await engine.initialize();
      await engine.addTorrent('a' * 40);
      final existing = engine.torrents.length;
      expect(
        () => engine.addTorrent('a' * 40),
        throwsA(isA<TorrentInputException>()),
      );
      expect(engine.torrents.length, existing);
    });

    test('addTorrent emits a TorrentTaskUpdated event', () async {
      await engine.initialize();
      final eventFuture = engine.events.first;
      await engine.addTorrent('a' * 40);
      final event = await eventFuture;
      expect(event, isA<TorrentTaskUpdated>());
    });

    test('addTorrent assigns info hash for .torrent file paths',
        () async {
      await engine.initialize();
      await engine.addTorrent('/path/to/file.torrent');
      final added = engine.torrents.first;
      expect(added.infoHash, hasLength(40));
    });

    test('toggleTorrent pauses a downloading torrent', () async {
      await engine.initialize();
      final torrent = engine.torrents.firstWhere((t) => t.status.isRunning);
      await engine.toggleTorrent(torrent.id);
      final updated = engine.torrents.firstWhere((t) => t.id == torrent.id);
      expect(updated.status, TorrentStatus.paused);
    });

    test('toggleTorrent resumes a paused torrent', () async {
      await engine.initialize();
      final running = engine.torrents.firstWhere((t) => t.status.isRunning);
      await engine.toggleTorrent(running.id);
      final paused = engine.torrents.firstWhere((t) => t.id == running.id);
      expect(paused.status, TorrentStatus.paused);
      await engine.toggleTorrent(paused.id);
      final resumed = engine.torrents.firstWhere((t) => t.id == running.id);
      expect(resumed.status.isRunning, isTrue);
    });

    test('toggleTorrent does nothing for finished torrents',
        () async {
      await engine.initialize();
      final finished =
          engine.torrents.firstWhere((t) => t.status == TorrentStatus.finished);
      await engine.toggleTorrent(finished.id);
      final unchanged =
          engine.torrents.firstWhere((t) => t.id == finished.id);
      expect(unchanged.status, TorrentStatus.finished);
    });

    test('resumeAll resumes all toggleable torrents', () async {
      await engine.initialize();
      await engine.pauseAll();
      await engine.resumeAll();
      expect(
        engine.torrents
            .where((t) => t.status.canToggle)
            .every((t) => t.status.isRunning),
        isTrue,
      );
    });

    test('pauseAll pauses all running torrents', () async {
      await engine.initialize();
      await engine.pauseAll();
      expect(
        engine.torrents
            .where((t) => t.status.canToggle)
            .every((t) => !t.status.isRunning),
        isTrue,
      );
    });

    test('deleteTorrent removes a torrent', () async {
      await engine.initialize();
      final before = engine.torrents.length;
      await engine.deleteTorrent(engine.torrents.first.id);
      expect(engine.torrents.length, before - 1);
    });

    test('deleteTorrent does nothing for unknown id', () async {
      await engine.initialize();
      final before = engine.torrents.length;
      await engine.deleteTorrent('nonexistent');
      expect(engine.torrents.length, before);
    });

    test('reorderQueue changes queue numbers', () async {
      await engine.initialize();
      final reordered = engine.torrents.reversed.map((t) => t.id).toList();
      await engine.reorderQueue(reordered);
      final ids = engine.torrents.map((t) => t.id).toList();
      expect(ids, reordered);
    });

    test('updateSort changes the sort option', () async {
      await engine.initialize();
      await engine.updateSort(TorrentSortOption.name);
      expect(engine.sortOption, TorrentSortOption.name);
    });

    test('visibleTorrents returns filtered results by bucket',
        () async {
      await engine.initialize();
      final finished = engine.visibleTorrents(
        bucket: TorrentBucket.finished,
        query: '',
      );
      expect(finished.every((t) => t.status == TorrentStatus.finished), isTrue);
    });

    test('visibleTorrents filters by query text', () async {
      await engine.initialize();
      final result = engine.visibleTorrents(
        bucket: TorrentBucket.all,
        query: 'ubuntu',
      );
      expect(result.every((t) => t.name.toLowerCase().contains('ubuntu')),
          isTrue);
    });

    test('validateNewTorrentSource returns null for valid source',
        () async {
      expect(engine.validateNewTorrentSource('a' * 40), isNull);
    });

    test('validateNewTorrentSource returns error for invalid source',
        () async {
      expect(engine.validateNewTorrentSource('not valid'), isNotNull);
    });

    test('handleNotificationAction handles pause', () async {
      await engine.initialize();
      engine.handleNotificationAction('pause_all');
      expect(engine.isShutdown, isFalse);
    });

    test('handleNotificationAction handles resume', () async {
      await engine.initialize();
      await engine.pauseAll();
      engine.handleNotificationAction('resume_all');
      expect(
        engine.torrents
            .where((t) => t.status.canToggle)
            .any((t) => t.status.isRunning),
        isTrue,
      );
    });

    test('triggerConstraintCheck does not throw', () async {
      await engine.initialize();
      await engine.triggerConstraintCheck();
    });

    test('activeTorrentCount returns correct count', () async {
      await engine.initialize();
      final running =
          engine.torrents.where((t) => t.status.isRunning).length;
      expect(engine.activeTorrentCount, running);
    });

    test('finishedTorrentCount returns correct count', () async {
      await engine.initialize();
      final finished =
          engine.torrents.where((t) => t.status == TorrentStatus.finished).length;
      expect(engine.finishedTorrentCount, finished);
    });

    test('torrents list is unmodifiable', () async {
      await engine.initialize();
      expect(
        () => (engine.torrents as dynamic).add(null),
        throwsA(anything),
      );
    });

    test('shutdown pauses all and updates state', () async {
      await engine.initialize();
      await engine.shutdown();
      expect(engine.isShutdown, isTrue);
      expect(
        engine.torrents.every(
          (t) => t.status == TorrentStatus.finished || !t.status.isRunning,
        ),
        isTrue,
      );
    });
  });
}
