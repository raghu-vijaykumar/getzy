import '../torrents/torrent_database.dart';

class SettingsRepository {
  SettingsRepository._();
  static final SettingsRepository instance = SettingsRepository._();
  final TorrentDatabase _database = TorrentDatabase.instance;

  Future<void> saveValue(String key, String value) async {
    await _database.upsertSetting(key, value);
  }

  Future<String?> loadValue(String key) async {
    return _database.getSetting(key);
  }
}
