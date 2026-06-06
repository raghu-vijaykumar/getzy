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

  Future<void> updateQueueOrder(List<String> orderedIds) async {
    await _database.updateQueueOrder(orderedIds);
  }
}
