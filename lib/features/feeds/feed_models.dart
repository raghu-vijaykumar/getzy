import 'package:xml/xml.dart';

class RssFeed {
  const RssFeed({
    required this.name,
    required this.url,
    required this.autoDownload,
    required this.lastRefreshed,
  });

  final String name;
  final String url;
  final bool autoDownload;
  final DateTime lastRefreshed;

  RssFeed copyWith({
    String? name,
    String? url,
    bool? autoDownload,
    DateTime? lastRefreshed,
  }) {
    return RssFeed(
      name: name ?? this.name,
      url: url ?? this.url,
      autoDownload: autoDownload ?? this.autoDownload,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
    );
  }

  factory RssFeed.fromMap(Map<String, Object?> map) {
    return RssFeed(
      name: map['name'] as String,
      url: map['url'] as String,
      autoDownload: (map['auto_download'] as int) == 1,
      lastRefreshed:
          DateTime.fromMillisecondsSinceEpoch(map['last_refreshed'] as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'url': url,
      'auto_download': autoDownload ? 1 : 0,
      'last_refreshed': lastRefreshed.millisecondsSinceEpoch,
    };
  }

  String get lastRefreshedString {
    final age = DateTime.now().difference(lastRefreshed);
    if (age < const Duration(minutes: 1)) {
      return 'just now';
    }
    if (age < const Duration(hours: 1)) {
      return '${age.inMinutes} minutes ago';
    }
    if (age < const Duration(days: 1)) {
      return '${age.inHours} hours ago';
    }
    return '${age.inDays} days ago';
  }
}

class RssItem {
  const RssItem({
    required this.title,
    required this.link,
    required this.publishedDate,
    this.torrentSource,
  });

  final String title;
  final String link;
  final DateTime? publishedDate;
  final String? torrentSource;

  factory RssItem.fromXmlElement(XmlElement element) {
    final titleSource = element.getElement('title')?.innerText;
    final linkSource = element.getElement('link')?.innerText;
    final pubDateSource = element.getElement('pubDate')?.innerText;
    final title = titleSource?.trim() ?? 'Untitled item';
    final link = linkSource?.trim() ?? '';
    final pubDate = pubDateSource?.trim();
    final published = pubDate != null
        ? (_tryParseRssDate(pubDate) ?? DateTime.tryParse(pubDate))
        : null;
    final enclosure = element.getElement('enclosure')?.getAttribute('url');
    final torrentSource =
        _sourceFromLink(link) ?? _sourceFromLink(enclosure ?? '');

    return RssItem(
      title: title,
      link: link,
      publishedDate: published,
      torrentSource: torrentSource,
    );
  }

  static DateTime? _tryParseRssDate(String date) {
    // RFC 2822: "Mon, 01 Jun 2024 12:00:00 GMT"
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final m = RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})')
        .firstMatch(date);
    if (m == null) return null;
    final month = months[m.group(2)!]!;
    final day = int.parse(m.group(1)!);
    final year = int.parse(m.group(3)!);
    final hour = int.parse(m.group(4)!);
    final minute = int.parse(m.group(5)!);
    final second = int.parse(m.group(6)!);
    return DateTime.utc(year, month, day, hour, minute, second);
  }

  static String? _sourceFromLink(String source) {
    if (source.isEmpty) {
      return null;
    }
    final normalized = source.trim();
    if (normalized.startsWith('magnet:?xt=urn:btih:') ||
        normalized.toLowerCase().endsWith('.torrent') ||
        RegExp(r'^[a-f0-9]{40}$', caseSensitive: false).hasMatch(normalized)) {
      return normalized;
    }
    return null;
  }
}
