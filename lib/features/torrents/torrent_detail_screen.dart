import 'package:flutter/material.dart';

import '../../app/getzy_theme.dart';
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
    final files = _sampleTorrentFiles(torrent.name);
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
          const Text('Torrent details', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 18),
          Text('Status: ${torrent.status.label}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text('Progress: ${(torrent.progress * 100).round()}%',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          const Text('Files',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final item in files)
            Card(
              color: GetzyColors.surface,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(item.path),
                subtitle: Text('${item.percentage}% • ${item.progressLabel}'),
                trailing: DropdownButton<FilePriority>(
                  value: item.priority,
                  items: FilePriority.values
                      .map((priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority.label),
                          ))
                      .toList(),
                  onChanged: (_) {},
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text('Trackers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final tracker in trackers)
            ListTile(
              leading: const Icon(Icons.public),
              title: Text(tracker),
            ),
          const SizedBox(height: 24),
          const Text('Peers',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final peer in peers)
            ListTile(
              leading: const Icon(Icons.wifi),
              title: Text(peer),
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

class TorrentFileInfo {
  TorrentFileInfo({
    required this.path,
    required this.percentage,
    required this.progressLabel,
    required this.priority,
  });

  final String path;
  final int percentage;
  final String progressLabel;
  final FilePriority priority;
}

enum FilePriority { high, normal, low }

extension FilePriorityLabel on FilePriority {
  String get label {
    switch (this) {
      case FilePriority.high:
        return 'High';
      case FilePriority.normal:
        return 'Normal';
      case FilePriority.low:
        return 'Low';
    }
  }
}

List<TorrentFileInfo> _sampleTorrentFiles(String torrentName) {
  return [
    TorrentFileInfo(
      path: '$torrentName / setup.exe',
      percentage: 100,
      progressLabel: 'Finished',
      priority: FilePriority.normal,
    ),
    TorrentFileInfo(
      path: '$torrentName / readme.txt',
      percentage: 100,
      progressLabel: 'Finished',
      priority: FilePriority.low,
    ),
    TorrentFileInfo(
      path: '$torrentName / images/cover.png',
      percentage: 68,
      progressLabel: 'Downloading',
      priority: FilePriority.high,
    ),
  ];
}
