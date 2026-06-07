import 'package:flutter_test/flutter_test.dart';
import 'package:getzy/features/torrents/torrent_validators.dart';

void main() {
  group('looksLikeTorrentSource', () {
    test('accepts a 40-character hex info hash', () {
      expect(looksLikeTorrentSource('a' * 40), isTrue);
      expect(looksLikeTorrentSource('ABCDEF0123456789abcdef0123456789abcdef01'),
          isTrue);
    });

    test('rejects a non-hex 40-character string', () {
      expect(looksLikeTorrentSource('z' * 40), isFalse);
      expect(looksLikeTorrentSource('x' * 40), isFalse);
    });

    test('rejects an empty string', () {
      expect(looksLikeTorrentSource(''), isFalse);
    });

    test('rejects a short string', () {
      expect(looksLikeTorrentSource('abc123'), isFalse);
    });

    test('accepts a magnet link', () {
      expect(
        looksLikeTorrentSource(
            'magnet:?xt=urn:btih:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
        isTrue,
      );
    });

    test('accepts an HTTP torrent URL', () {
      expect(
        looksLikeTorrentSource(
            'https://example.com/file.torrent'),
        isTrue,
      );
      expect(
        looksLikeTorrentSource(
            'http://example.com/file.torrent'),
        isTrue,
      );
    });

    test('accepts a local .torrent file path', () {
      expect(
          looksLikeTorrentSource('/storage/emulated/0/Download/file.torrent'),
          isTrue);
      expect(looksLikeTorrentSource('C:\\Downloads\\file.torrent'), isTrue);
    });

    test('rejects an HTTP URL that does not end with .torrent', () {
      expect(
          looksLikeTorrentSource('https://example.com/file.txt'), isFalse);
    });

    test('is case insensitive', () {
      expect(looksLikeTorrentSource('A' * 40), isTrue);
      expect(
        looksLikeTorrentSource(
            'MAGNET:?XT=URN:BTIH:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
        isTrue,
      );
    });
  });

  group('validateTorrentSource', () {
    test('returns null for a valid info hash', () {
      expect(validateTorrentSource('a' * 40), isNull);
    });

    test('returns null for a valid magnet link', () {
      expect(
        validateTorrentSource(
            'magnet:?xt=urn:btih:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
        isNull,
      );
    });

    test('returns an error for an empty string', () {
      expect(validateTorrentSource(''), isNotNull);
    });

    test('returns an error for an invalid string', () {
      expect(validateTorrentSource('not a torrent source'), isNotNull);
    });
  });

  group('extractTorrentInfoHash', () {
    test('extracts a direct 40-character info hash', () {
      expect(
        extractTorrentInfoHash('a' * 40),
        equals('a' * 40),
      );
    });

    test('extracts from a magnet link', () {
      expect(
        extractTorrentInfoHash(
            'magnet:?xt=urn:btih:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
        equals('a' * 40),
      );
    });

    test('extracts from a short magnet hash (32 chars) with padding', () {
      expect(
        extractTorrentInfoHash(
            'magnet:?xt=urn:btih:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
        hasLength(40),
      );
    });

    test('extracts from a .torrent file path', () {
      final hash = extractTorrentInfoHash('/path/to/file.torrent');
      expect(hash, hasLength(40));
      expect(hash, matches(r'^[a-f0-9]{40}$'));
    });

    test('normalizes to lowercase', () {
      expect(
        extractTorrentInfoHash('A' * 40),
        equals('a' * 40),
      );
    });
  });

  group('needsStoragePermission', () {
    test('returns true for a local .torrent file path', () {
      expect(
        needsStoragePermission('/storage/emulated/0/file.torrent'),
        isTrue,
      );
    });

    test('returns false for an HTTP .torrent URL', () {
      expect(
        needsStoragePermission('https://example.com/file.torrent'),
        isFalse,
      );
    });

    test('returns false for a magnet link', () {
      expect(
        needsStoragePermission(
            'magnet:?xt=urn:btih:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
        isFalse,
      );
    });

    test('returns false for an info hash', () {
      expect(needsStoragePermission('a' * 40), isFalse);
    });
  });
}
