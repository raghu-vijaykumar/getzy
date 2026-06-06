import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../feeds/feed_models.dart';
import 'torrent_models.dart';

class TorrentDatabase {
  TorrentDatabase._();

  static final TorrentDatabase instance = TorrentDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'getzy.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createSchema,
    );
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE torrents(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        info_hash TEXT NOT NULL,
        queue_number INTEGER NOT NULL,
        status TEXT NOT NULL,
        progress REAL NOT NULL,
        downloaded_bytes INTEGER NOT NULL,
        total_bytes INTEGER NOT NULL,
        download_speed_bytes INTEGER NOT NULL,
        upload_speed_bytes INTEGER NOT NULL,
        date_added INTEGER NOT NULL,
        date_finished INTEGER,
        eta_seconds INTEGER,
        blocked_reason TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE feeds(
        url TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        auto_download INTEGER NOT NULL,
        last_refreshed INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<List<TorrentTask>> loadTorrents() async {
    final db = await database;
    final rows = await db.query('torrents', orderBy: 'queue_number ASC');
    return rows.map(TorrentTask.fromMap).toList();
  }

  Future<void> upsertTorrent(TorrentTask task) async {
    final db = await database;
    await db.insert(
      'torrents',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTorrent(String id) async {
    final db = await database;
    await db.delete('torrents', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateQueueOrder(List<String> orderedIds) async {
    final db = await database;
    final batch = db.batch();
    for (var index = 0; index < orderedIds.length; index++) {
      batch.update(
        'torrents',
        {'queue_number': index + 1},
        where: 'id = ?',
        whereArgs: [orderedIds[index]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<RssFeed>> loadFeeds() async {
    final db = await database;
    final rows = await db.query('feeds', orderBy: 'name ASC');
    return rows.map(RssFeed.fromMap).toList();
  }

  Future<void> upsertFeed(RssFeed feed) async {
    final db = await database;
    await db.insert(
      'feeds',
      feed.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFeed(String url) async {
    final db = await database;
    await db.delete('feeds', where: 'url = ?', whereArgs: [url]);
  }

  Future<void> upsertSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }
}
