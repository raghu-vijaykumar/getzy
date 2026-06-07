import 'package:flutter_test/flutter_test.dart';
import 'package:getzy/features/torrents/torrent_models.dart';

void main() {
  group('TorrentStatus', () {
    test('labels are human-readable', () {
      expect(TorrentStatus.queued.label, 'Queued');
      expect(TorrentStatus.downloading.label, 'Downloading');
      expect(TorrentStatus.paused.label, 'Paused');
      expect(TorrentStatus.checking.label, 'Checking');
      expect(TorrentStatus.finished.label, 'Finished');
      expect(TorrentStatus.blocked.label, 'Blocked');
    });

    test('canToggle excludes finished and blocked', () {
      expect(TorrentStatus.queued.canToggle, isTrue);
      expect(TorrentStatus.downloading.canToggle, isTrue);
      expect(TorrentStatus.paused.canToggle, isTrue);
      expect(TorrentStatus.checking.canToggle, isTrue);
      expect(TorrentStatus.finished.canToggle, isFalse);
      expect(TorrentStatus.blocked.canToggle, isFalse);
    });

    test('isRunning includes downloading and checking', () {
      expect(TorrentStatus.queued.isRunning, isFalse);
      expect(TorrentStatus.downloading.isRunning, isTrue);
      expect(TorrentStatus.paused.isRunning, isFalse);
      expect(TorrentStatus.checking.isRunning, isTrue);
      expect(TorrentStatus.finished.isRunning, isFalse);
      expect(TorrentStatus.blocked.isRunning, isFalse);
    });

    test('fromString parses status names', () {
      expect(TorrentStatus.queued, TorrentStatusExtension.fromString('queued'));
      expect(TorrentStatus.downloading,
          TorrentStatusExtension.fromString('downloading'));
      expect(TorrentStatus.paused,
          TorrentStatusExtension.fromString('paused'));
      expect(TorrentStatus.finished,
          TorrentStatusExtension.fromString('finished'));
      expect(TorrentStatus.blocked,
          TorrentStatusExtension.fromString('blocked'));
    });

    test('fromString returns queued for unknown status', () {
      expect(
        TorrentStatusExtension.fromString('unknown'),
        TorrentStatus.queued,
      );
    });
  });

  group('TorrentSortOption', () {
    test('labels are human-readable', () {
      expect(TorrentSortOption.queueNumber.label, 'Queue number');
      expect(TorrentSortOption.name.label, 'Name');
      expect(TorrentSortOption.dateAdded.label, 'Date added');
      expect(TorrentSortOption.dateFinished.label, 'Date finished');
      expect(TorrentSortOption.downloadSpeed.label, 'Download speed');
      expect(TorrentSortOption.uploadSpeed.label, 'Upload speed');
      expect(TorrentSortOption.eta.label, 'ETA');
    });
  });

  group('formatBytes', () {
    test('formats 0 bytes', () {
      expect(formatBytes(0), '0.0 KB');
    });

    test('formats bytes in KB', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
    });

    test('formats bytes in MB', () {
      expect(formatBytes(1048576), '1.0 MB');
      expect(formatBytes(1572864), '1.5 MB');
    });

    test('formats bytes in GB', () {
      expect(formatBytes(1073741824), '1.0 GB');
    });

    test('formats bytes in TB', () {
      expect(formatBytes(1099511627776), '1.0 TB');
    });

    test('handles small values', () {
      expect(formatBytes(1), '1.0 B');
      expect(formatBytes(1023), '1023 B');
    });
  });

  group('formatSpeed', () {
    test('appends /s to formatBytes output', () {
      expect(formatSpeed(1024), '1.0 KB/s');
      expect(formatSpeed(1048576), '1.0 MB/s');
    });
  });

  group('formatEta', () {
    test('formats hours and minutes', () {
      expect(formatEta(const Duration(hours: 2, minutes: 30)), '2h 30m');
    });

    test('formats only minutes', () {
      expect(formatEta(const Duration(minutes: 5)), '5m');
    });

    test('formats hours and zero minutes', () {
      expect(formatEta(const Duration(hours: 1)), '1h 0m');
    });

    test('returns -- for null', () {
      expect(formatEta(null), '--');
    });
  });

  group('TorrentTask', () {
    final now = DateTime.now();
    final task = TorrentTask(
      id: 'test-1',
      name: 'Test Torrent',
      infoHash: 'a' * 40,
      queueNumber: 1,
      status: TorrentStatus.downloading,
      progress: 0.5,
      downloadedBytes: 500,
      totalBytes: 1000,
      downloadSpeedBytes: 100,
      uploadSpeedBytes: 50,
      dateAdded: now,
      eta: const Duration(minutes: 10),
    );

    test('copyWith creates a modified copy', () {
      final modified = task.copyWith(status: TorrentStatus.paused);
      expect(modified.status, TorrentStatus.paused);
      expect(modified.id, task.id);
      expect(modified.name, task.name);
    });

    test('toMap and fromMap round-trips', () {
      final map = task.toMap();
      final restored = TorrentTask.fromMap(map);
      expect(restored.id, task.id);
      expect(restored.name, task.name);
      expect(restored.infoHash, task.infoHash);
      expect(restored.queueNumber, task.queueNumber);
      expect(restored.status, task.status);
      expect(restored.progress, task.progress);
      expect(restored.downloadedBytes, task.downloadedBytes);
      expect(restored.totalBytes, task.totalBytes);
      expect(restored.downloadSpeedBytes, task.downloadSpeedBytes);
      expect(restored.uploadSpeedBytes, task.uploadSpeedBytes);
    });

    test('toMap includes optional fields', () {
      final map = task.toMap();
      expect(map['eta_seconds'], const Duration(minutes: 10).inSeconds);
    });

    test('fromMap restores eta', () {
      final map = task.toMap();
      final restored = TorrentTask.fromMap(map);
      expect(restored.eta, const Duration(minutes: 10));
    });

    test('fromMap handles null eta', () {
      final noEta = TorrentTask(
        id: 'no-eta',
        name: 'No ETA',
        infoHash: 'b' * 40,
        queueNumber: 2,
        status: TorrentStatus.queued,
        progress: 0,
        downloadedBytes: 0,
        totalBytes: 1000,
        downloadSpeedBytes: 0,
        uploadSpeedBytes: 0,
        dateAdded: DateTime.now(),
      );
      final map = noEta.toMap();
      expect(map['eta_seconds'], isNull);
      final restored = TorrentTask.fromMap(map);
      expect(restored.eta, isNull);
    });
  });

  group('TorrentFile', () {
    test('creates a torrent file with given values', () {
      final file = TorrentFile(
        path: 'test/file.txt',
        lengthBytes: 1024,
        priority: TorrentFilePriority.normal,
        progress: 0.0,
        selected: true,
      );
      expect(file.priority, TorrentFilePriority.normal);
    });
  });

  group('EngineSession', () {
    test('creates a session with initial values', () {
      final session = EngineSession(
        uploadedBytes: 0,
        downloadedBytes: 0,
        activeConnections: 0,
        lastUpdated: DateTime.now(),
      );
      expect(session.uploadedBytes, 0);
      expect(session.activeConnections, 0);
    });
  });
}
