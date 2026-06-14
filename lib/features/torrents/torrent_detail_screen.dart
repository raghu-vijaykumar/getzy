import 'package:flutter/material.dart';

import '../../app/getzy_theme.dart';
import 'file_tree_widget.dart';
import 'torrent_models.dart';
import 'torrent_engine.dart';

class TorrentDetailScreen extends StatelessWidget {
  const TorrentDetailScreen({
    required this.torrent,
    required this.engine,
    super.key,
  });

  final TorrentTask torrent;
  final TorrentEngine engine;

  @override
  Widget build(BuildContext context) {
    final c = GetzyColors.of(context);
    final fileEntries = _sampleFileTree(torrent.name);
    final trackers = ['tracker.openbittorrent.com', 'tracker.opentrackr.org'];
    final peers = ['23.45.1.12', '72.216.14.99'];

    return Scaffold(
      appBar: AppBar(
        title: Text(torrent.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove torrent',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Text('Torrent details', style: TextStyle(fontSize: 28, color: c.textPrimary)),
          const SizedBox(height: 18),
          Text('Status: ${torrent.status.label}',
              style: TextStyle(fontSize: 16, color: c.textSecondary)),
          const SizedBox(height: 6),
          Text('Progress: ${(torrent.progress * 100).round()}%',
              style: TextStyle(fontSize: 16, color: c.textSecondary)),
          const SizedBox(height: 24),
          Text('Files',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const SizedBox(height: 8),
          FileTreeWidget(roots: fileEntries),
          const SizedBox(height: 24),
          Text('Trackers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const SizedBox(height: 8),
          for (final tracker in trackers)
            ListTile(
              leading: Icon(Icons.public, color: c.textSecondary),
              title: Text(tracker, style: TextStyle(color: c.textPrimary)),
            ),
          const SizedBox(height: 24),
          Text('Peers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const SizedBox(height: 8),
          for (final peer in peers)
            ListTile(
              leading: Icon(Icons.wifi, color: c.textSecondary),
              title: Text(peer, style: TextStyle(color: c.textPrimary)),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove torrent'),
          content: const Text(
              'Remove this torrent from Getzy? This will not delete downloaded files.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove')),
          ],
        );
      },
    );

    if (confirmed == true) {
      await engine.deleteTorrent(torrent.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

List<FileTreeEntry> _sampleFileTree(String torrentName) {
  return [
    FileTreeEntry(name: '$torrentName/', children: [
      FileTreeEntry(
        name: 'ubuntu-24.04-desktop-amd64.iso',
        fullPath: '$torrentName/ubuntu-24.04-desktop-amd64.iso',
        percentage: 100,
        progressLabel: 'Finished',
      ),
      FileTreeEntry(
        name: 'SHA256SUMS',
        fullPath: '$torrentName/SHA256SUMS',
        percentage: 100,
        progressLabel: 'Finished',
      ),
      FileTreeEntry(
        name: 'SHA256SUMS.gpg',
        fullPath: '$torrentName/SHA256SUMS.gpg',
        percentage: 100,
        progressLabel: 'Finished',
      ),
      FileTreeEntry(name: 'images', children: [
        FileTreeEntry(
          name: 'logo.png',
          fullPath: '$torrentName/images/logo.png',
          percentage: 100,
          progressLabel: 'Finished',
        ),
        FileTreeEntry(
          name: 'screenshot.jpg',
          fullPath: '$torrentName/images/screenshot.jpg',
          percentage: 100,
          progressLabel: 'Finished',
        ),
      ]),
      FileTreeEntry(name: 'docs', children: [
        FileTreeEntry(
          name: 'README.txt',
          fullPath: '$torrentName/docs/README.txt',
          percentage: 100,
          progressLabel: 'Finished',
        ),
        FileTreeEntry(name: 'release-notes', children: [
          FileTreeEntry(
            name: 'whats-new.html',
            fullPath: '$torrentName/docs/release-notes/whats-new.html',
            percentage: 100,
            progressLabel: 'Finished',
          ),
          FileTreeEntry(
            name: 'known-issues.html',
            fullPath: '$torrentName/docs/release-notes/known-issues.html',
            percentage: 100,
            progressLabel: 'Finished',
          ),
        ]),
      ]),
      FileTreeEntry(name: 'extras', children: [
        FileTreeEntry(
          name: 'gnome-extensions.zip',
          fullPath: '$torrentName/extras/gnome-extensions.zip',
          percentage: 68,
          progressLabel: 'Downloading',
        ),
        FileTreeEntry(name: 'wallpapers', children: [
          FileTreeEntry(
            name: 'mountain.jpg',
            fullPath: '$torrentName/extras/wallpapers/mountain.jpg',
            percentage: 42,
            progressLabel: 'Downloading',
          ),
          FileTreeEntry(
            name: 'sunset.jpg',
            fullPath: '$torrentName/extras/wallpapers/sunset.jpg',
            percentage: 15,
            progressLabel: 'Downloading',
          ),
        ]),
      ]),
    ]),
  ];
}
