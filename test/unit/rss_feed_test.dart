import 'package:flutter_test/flutter_test.dart';
import 'package:getzy/features/feeds/feed_models.dart';
import 'package:xml/xml.dart';

void main() {
  group('RssFeed', () {
    test('creates a feed with given values', () {
      final feed = RssFeed(
        name: 'Test Feed',
        url: 'https://example.com/feed.xml',
        autoDownload: false,
        lastRefreshed: DateTime(2024, 1, 1),
      );
      expect(feed.name, 'Test Feed');
      expect(feed.url, 'https://example.com/feed.xml');
      expect(feed.autoDownload, false);
    });

    test('copyWith creates a modified copy', () {
      final feed = RssFeed(
        name: 'Original',
        url: 'https://example.com/feed.xml',
        autoDownload: false,
        lastRefreshed: DateTime(2024, 1, 1),
      );
      final modified = feed.copyWith(autoDownload: true);
      expect(modified.autoDownload, true);
      expect(modified.name, 'Original');
    });

    test('toMap and fromMap round-trips', () {
      final feed = RssFeed(
        name: 'Test Feed',
        url: 'https://example.com/feed.xml',
        autoDownload: true,
        lastRefreshed: DateTime(2024, 6, 1, 12, 30),
      );
      final map = feed.toMap();
      expect(map['name'], 'Test Feed');
      expect(map['url'], 'https://example.com/feed.xml');
      expect(map['auto_download'], 1);

      final restored = RssFeed.fromMap(map);
      expect(restored.name, feed.name);
      expect(restored.url, feed.url);
      expect(restored.autoDownload, feed.autoDownload);
    });

    test('lastRefreshedString returns "just now" for recent refresh', () {
      final feed = RssFeed(
        name: 'Test',
        url: 'https://example.com/feed.xml',
        autoDownload: false,
        lastRefreshed: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(feed.lastRefreshedString, 'just now');
    });

    test('lastRefreshedString returns "5 minutes ago"', () {
      final feed = RssFeed(
        name: 'Test',
        url: 'https://example.com/feed.xml',
        autoDownload: false,
        lastRefreshed:
            DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(feed.lastRefreshedString, '5 minutes ago');
    });

    test('lastRefreshedString returns "2 hours ago"', () {
      final feed = RssFeed(
        name: 'Test',
        url: 'https://example.com/feed.xml',
        autoDownload: false,
        lastRefreshed:
            DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(feed.lastRefreshedString, '2 hours ago');
    });

    test('lastRefreshedString returns "3 days ago"', () {
      final feed = RssFeed(
        name: 'Test',
        url: 'https://example.com/feed.xml',
        autoDownload: false,
        lastRefreshed: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(feed.lastRefreshedString, '3 days ago');
    });
  });

  group('RssItem', () {
    XmlElement parseItem(String xml) {
      return XmlDocument.parse(xml).rootElement;
    }

    test('parses title, link, and pubDate from XML', () {
      final item = RssItem.fromXmlElement(parseItem('''
<item>
  <title>Ubuntu 24.04 LTS Released</title>
  <link>https://example.com/ubuntu-24.04.torrent</link>
  <pubDate>Mon, 01 Jun 2024 12:00:00 GMT</pubDate>
</item>
'''));
      expect(item.title, 'Ubuntu 24.04 LTS Released');
      expect(item.link, 'https://example.com/ubuntu-24.04.torrent');
      expect(item.publishedDate, isNotNull);
    });

    test('detects magnet link as torrent source', () {
      final item = RssItem.fromXmlElement(parseItem('''
<item>
  <title>Test Torrent</title>
  <link>magnet:?xt=urn:btih:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa</link>
  <pubDate>Mon, 01 Jun 2024 12:00:00 GMT</pubDate>
</item>
'''));
      expect(item.torrentSource, isNotNull);
      expect(item.torrentSource, contains('magnet:'));
    });

    test('detects .torrent URL as torrent source', () {
      final item = RssItem.fromXmlElement(parseItem('''
<item>
  <title>File Torrent</title>
  <link>https://example.com/file.torrent</link>
  <pubDate>Mon, 01 Jun 2024 12:00:00 GMT</pubDate>
</item>
'''));
      expect(item.torrentSource, isNotNull);
      expect(item.torrentSource, contains('.torrent'));
    });

    test('torrentSource is null for non-torrent links', () {
      final item = RssItem.fromXmlElement(parseItem('''
<item>
  <title>News Article</title>
  <link>https://example.com/article</link>
  <pubDate>Mon, 01 Jun 2024 12:00:00 GMT</pubDate>
</item>
'''));
      expect(item.torrentSource, isNull);
    });

    test('handles missing pubDate gracefully', () {
      final item = RssItem.fromXmlElement(parseItem('''
<item>
  <title>No Date Item</title>
  <link>https://example.com/file.torrent</link>
</item>
'''));
      expect(item.title, 'No Date Item');
      expect(item.publishedDate, isNull);
    });

    test('handles empty title gracefully', () {
      final item = RssItem.fromXmlElement(parseItem('''
<item>
  <title></title>
  <link>https://example.com/file.torrent</link>
</item>
'''));
      expect(item.title, isEmpty);
    });
  });
}
