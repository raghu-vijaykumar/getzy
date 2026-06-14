import 'package:flutter/material.dart';

import '../../app/getzy_theme.dart';
import 'torrent_engine.dart';
import 'torrent_models.dart';

class QueueEditorScreen extends StatefulWidget {
  const QueueEditorScreen({required this.engine, super.key});

  final TorrentEngine engine;

  @override
  State<QueueEditorScreen> createState() => _QueueEditorScreenState();
}

class _QueueEditorScreenState extends State<QueueEditorScreen> {
  late List<TorrentTask> _orderedTorrents;

  @override
  void initState() {
    super.initState();
    _orderedTorrents = widget.engine.torrents.toList()
      ..sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = _orderedTorrents.removeAt(oldIndex);
    _orderedTorrents.insert(newIndex, item);
    widget.engine.reorderQueue(_orderedTorrents.map((t) => t.id).toList());
    setState(() {
      _orderedTorrents = widget.engine.torrents.toList()
        ..sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = GetzyColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify queue'),
        actions: [
          TextButton(
            onPressed: () {
              widget.engine
                  .reorderQueue(_orderedTorrents.map((t) => t.id).toList());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Queue order updated')),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        itemCount: _orderedTorrents.length,
        onReorder: _onReorder,
        itemBuilder: (context, index) {
          final torrent = _orderedTorrents[index];
          return Card(
            key: ValueKey(torrent.id),
            color: c.elevated,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: c.action,
                child: Text('${torrent.queueNumber}',
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text(torrent.name),
              subtitle: Text(torrent.status.label),
              trailing: Icon(Icons.drag_handle,
                  color: c.textSecondary),
            ),
          );
        },
      ),
    );
  }
}
