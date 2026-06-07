bool looksLikeTorrentSource(String source) {
  final normalized = source.trim().toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }

  final isInfoHash =
      RegExp(r'^[a-f0-9]{40}$', caseSensitive: false).hasMatch(normalized);
  final isMagnet = normalized.startsWith('magnet:?xt=urn:btih:');
  final isTorrentLink =
      (normalized.startsWith('http://') || normalized.startsWith('https://')) &&
          normalized.endsWith('.torrent');
  final isTorrentFile = normalized.endsWith('.torrent');

  return isMagnet || isInfoHash || isTorrentLink || isTorrentFile;
}

String extractTorrentInfoHash(String source) {
  final normalized = source.trim();
  final directHash =
      RegExp(r'^[a-f0-9]{40}$', caseSensitive: false).firstMatch(normalized);
  if (directHash != null) {
    return normalized.toLowerCase();
  }

  final magnetMatch = RegExp(r'btih:([a-z0-9]{32,40})', caseSensitive: false)
      .firstMatch(normalized);
  if (magnetMatch != null) {
    return magnetMatch
        .group(1)!
        .toLowerCase()
        .padRight(40, '0')
        .substring(0, 40);
  }

  if (normalized.endsWith('.torrent')) {
    return normalized.hashCode
        .abs()
        .toRadixString(16)
        .padLeft(40, '0')
        .substring(0, 40);
  }

  return normalized.hashCode
      .abs()
      .toRadixString(16)
      .padLeft(40, '0')
      .substring(0, 40);
}

String? validateTorrentSource(String source) {
  if (source.trim().isEmpty) {
    return 'Enter a magnet link, info hash, or torrent URL.';
  }
  if (!looksLikeTorrentSource(source)) {
    return 'Use a magnet link, 40-character info hash, or .torrent URL.';
  }
  return null;
}

bool needsStoragePermission(String source) {
  final lower = source.trim().toLowerCase();
  return lower.endsWith('.torrent') && !lower.startsWith('http');
}
