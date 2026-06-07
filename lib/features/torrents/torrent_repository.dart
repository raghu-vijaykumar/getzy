import 'package:path/path.dart' as p;
import 'torrent_database.dart';
import 'torrent_models.dart';

class TorrentRepository {
  TorrentRepository._();
  static final TorrentRepository instance = TorrentRepository._();
  final TorrentDatabase _database = TorrentDatabase.instance;

  Future<List<TorrentTask>> loadTorrents() async {
    return _database.loadTorrents();
  }

  Future<void> saveTorrent(TorrentTask torrent) async {
    await _database.upsertTorrent(torrent);
  }

  Future<void> saveTorrents(List<TorrentTask> torrents) async {
    for (final torrent in torrents) {
      await saveTorrent(torrent);
    }
  }

  Future<void> deleteTorrent(String id) async {
    await _database.deleteTorrent(id);
  }

  Future<void> importFromDirectory(String directoryPath) async {
    // T036 implementation
    // In a real Android environment, this would use a DirectoryStream 
    // or a FileWatcher to find .torrent files and add them.
    final dir = p.Directory(directoryPath);
    if (await dir.exists()) {
      final files = dir.listSync().where((f) => f.path.endsWith('.torrent')).toList();
      for (var file in files) {
        // Mocking the import of torrent files
        final torrent = TorrentTask(
          id: 'imported-${DateTime.now().millisecondsSinceEpoch}',
          name: p.basename(file.path),
          status: TorrentStatus.queued,
          progress: 0.0,
        );
        await saveTorrent(torrent);
      }
    }
  }
}
