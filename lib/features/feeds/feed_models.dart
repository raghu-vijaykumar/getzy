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
    final titleSource = element.getElement('title')?.value;
    final linkSource = element.getElement('link')?.value;
    final pubDateSource = element.getElement('pubDate')?.value;
    final title = titleSource?.trim() ?? 'Untitled item';
    final link = linkSource?.trim() ?? '';
    final pubDate = pubDateSource?.trim();
    final published = pubDate != null ? DateTime.tryParse(pubDate) : null;
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
