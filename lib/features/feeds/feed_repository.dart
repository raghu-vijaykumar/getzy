import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../torrents/torrent_engine.dart';
import '../torrents/torrent_engine_platform.dart';
import '../torrents/torrent_database.dart';
import 'feed_models.dart';

class FeedFetchException implements Exception {
  FeedFetchException(this.message);
  final String message;

  @override
  String toString() => 'FeedFetchException: $message';
}

class FeedRepository {
  FeedRepository._();
  static final FeedRepository instance = FeedRepository._();
  final TorrentDatabase _database = TorrentDatabase.instance;

  Future<List<RssFeed>> loadFeeds() async {
    return _database.loadFeeds();
  }

  Future<void> addFeed(RssFeed feed) async {
    await _database.upsertFeed(feed);
  }

  Future<void> removeFeed(String url) async {
    await _database.deleteFeed(url);
  }

  Future<List<RssItem>> fetchFeedItems(RssFeed feed) async {
    try {
      final response = await http
          .get(Uri.parse(feed.url))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw FeedFetchException(
            'Feed request failed with status ${response.statusCode}');
      }

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');
      return items.map(RssItem.fromXmlElement).toList();
    } on TimeoutException {
      throw FeedFetchException('Feed request timed out');
    } on XmlParserException catch (error) {
      throw FeedFetchException('Failed to parse feed: ${error.message}');
    } catch (error) {
      throw FeedFetchException(error.toString());
    }
  }

  Future<void> refreshFeed(RssFeed feed, TorrentEngine? engine) async {
    final items = await fetchFeedItems(feed);
    final updatedFeed = feed.copyWith(lastRefreshed: DateTime.now());
    await _database.upsertFeed(updatedFeed);

    if (!feed.autoDownload) {
      return;
    }

    final torrentSources = <String>{};
    for (final item in items) {
      if (item.torrentSource != null) {
        torrentSources.add(item.torrentSource!);
      }
    }
    for (final source in torrentSources) {
      if (engine != null) {
        try {
          await engine.addTorrent(source);
        } catch (_) {
          // Ignore duplicates and validation failures from automatic imports.
        }
      } else {
        await TorrentEnginePlatform.addTorrent(source);
      }
    }
  }
}
