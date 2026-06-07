import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/getzy_theme.dart';
import '../feeds/feed_manager_screen.dart';
import '../session/session_status_screen.dart';
import '../settings/settings_screen.dart';
import 'queue_editor_screen.dart';
import 'torrent_detail_screen.dart';
import 'torrent_engine.dart';
import 'torrent_models.dart';

enum _OverflowAction {
  feeds,
  resumeAll,
  pauseAll,
  modifyQueue,
  sessionStatus,
  settings,
  shutdown,
}

class TorrentHomeScreen extends StatefulWidget {
  const TorrentHomeScreen({required this.engine, super.key});

  final TorrentEngine engine;

  @override
  State<TorrentHomeScreen> createState() => _TorrentHomeScreenState();
}

class _TorrentHomeScreenState extends State<TorrentHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AnimatedBuilder(
        animation: widget.engine,
        builder: (context, child) {
          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showAddTorrentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add torrent'),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _buildToolbar(context),
                  const TabBar(
                    tabs: [
                      Tab(text: 'ALL'),
                      Tab(text: 'QUEUED'),
                      Tab(text: 'FINISHED'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _TorrentList(
                          torrents: widget.engine.visibleTorrents(
                            bucket: TorrentBucket.all,
                            query: _query,
                          ),
                          onToggle: widget.engine.toggleTorrent,
                          onOpenDetails: (torrent) =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TorrentDetailScreen(
                                torrent: torrent,
                                engine: widget.engine,
                              ),
                            ),
                          ),
                        ),
                        _TorrentList(
                          torrents: widget.engine.visibleTorrents(
                            bucket: TorrentBucket.queued,
                            query: _query,
                          ),
                          onToggle: widget.engine.toggleTorrent,
                          onOpenDetails: (torrent) =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TorrentDetailScreen(
                                torrent: torrent,
                                engine: widget.engine,
                              ),
                            ),
                          ),
                        ),
                        _TorrentList(
                          torrents: widget.engine.visibleTorrents(
                            bucket: TorrentBucket.finished,
                            query: _query,
                          ),
                          onToggle: widget.engine.toggleTorrent,
                          onOpenDetails: (torrent) =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TorrentDetailScreen(
                                torrent: torrent,
                                engine: widget.engine,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 14),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Close search',
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _query = '';
                  _searchController.clear();
                });
              },
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search torrent',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 12, 18),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Getzy',
              style: TextStyle(fontSize: 30, color: GetzyColors.textPrimary),
            ),
          ),
          IconButton(
            tooltip: 'Search torrents',
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearching = true),
          ),
          IconButton(
            tooltip: 'Add magnet link',
            icon: const Icon(Icons.add_link),
            onPressed: _showAddTorrentDialog,
          ),
          IconButton(
            tooltip: 'Sort torrents',
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
          PopupMenuButton<_OverflowAction>(
            tooltip: 'More actions',
            color: GetzyColors.surface,
            onSelected: _handleOverflowAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _OverflowAction.feeds,
                child: _MenuItem(icon: Icons.rss_feed, label: 'Feeds'),
              ),
              PopupMenuItem(
                value: _OverflowAction.resumeAll,
                child: _MenuItem(icon: Icons.play_arrow, label: 'Resume all'),
              ),
              PopupMenuItem(
                value: _OverflowAction.pauseAll,
                child: _MenuItem(icon: Icons.pause, label: 'Pause all'),
              ),
              PopupMenuItem(
                value: _OverflowAction.modifyQueue,
                child:
                    _MenuItem(icon: Icons.low_priority, label: 'Modify queue'),
              ),
              PopupMenuItem(
                value: _OverflowAction.sessionStatus,
                child: _MenuItem(
                    icon: Icons.stacked_line_chart, label: 'Session status'),
              ),
              PopupMenuItem(
                value: _OverflowAction.settings,
                child: _MenuItem(icon: Icons.settings, label: 'Settings'),
              ),
              PopupMenuItem(
                value: _OverflowAction.shutdown,
                child: _MenuItem(
                    icon: Icons.power_settings_new, label: 'Shutdown'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTorrentDialog() async {
    try {
      final source = await showDialog<String>(
        context: context,
        builder: (context) => _AddTorrentDialog(engine: widget.engine),
      );

      if (source == null) {
        return;
      }

      await widget.engine.addTorrent(source);
      _showSnackBar('Torrent added to queue');
    } on TorrentInputException catch (error) {
      _showSnackBar(error.message);
    }
  }

  Future<void> _showSortDialog() async {
    TorrentSortOption selectedOption = widget.engine.sortOption;

    final option = await showDialog<TorrentSortOption>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Sort by', style: TextStyle(fontSize: 30)),
              content: SizedBox(
                width: 420,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: TorrentSortOption.values.map((sortOption) {
                      return RadioListTile<TorrentSortOption>(
                      value: sortOption,
                      groupValue: selectedOption,
                      activeColor: GetzyColors.accent,
                      title: Text(sortOption.label),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedOption = value);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(selectedOption),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (option != null) {
      widget.engine.updateSort(option);
    }
  }

  void _handleOverflowAction(_OverflowAction action) {
    switch (action) {
      case _OverflowAction.feeds:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FeedManagerScreen(engine: widget.engine)));
        break;
      case _OverflowAction.resumeAll:
        widget.engine.resumeAll();
        _showSnackBar('All eligible torrents resumed');
        break;
      case _OverflowAction.pauseAll:
        widget.engine.pauseAll();
        _showSnackBar('All torrents paused');
        break;
      case _OverflowAction.modifyQueue:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => QueueEditorScreen(engine: widget.engine)));
        break;
      case _OverflowAction.sessionStatus:
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => SessionStatusScreen(engine: widget.engine)),
        );
        break;
      case _OverflowAction.settings:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SettingsScreen(engine: widget.engine)));
        break;
      case _OverflowAction.shutdown:
        widget.engine.shutdown();
        _showSnackBar('Engine shutdown simulated');
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TorrentList extends StatelessWidget {
  const _TorrentList({
    required this.torrents,
    required this.onToggle,
    required this.onOpenDetails,
  });

  final List<TorrentTask> torrents;
  final ValueChanged<String> onToggle;
  final ValueChanged<TorrentTask> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    if (torrents.isEmpty) {
      return const Center(
        child: Text(
          'No torrents here',
          style: TextStyle(color: GetzyColors.textSecondary, fontSize: 18),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 112),
      itemCount: torrents.length,
      separatorBuilder: (context, index) =>
          const Divider(indent: 18, endIndent: 18),
      itemBuilder: (context, index) {
        final torrent = torrents[index];
        return _TorrentTile(
          torrent: torrent,
          onToggle: () => onToggle(torrent.id),
          onOpenDetails: () => onOpenDetails(torrent),
        );
      },
    );
  }
}

class _AddTorrentDialog extends StatefulWidget {
  const _AddTorrentDialog({required this.engine});

  final TorrentEngine engine;

  @override
  State<_AddTorrentDialog> createState() => _AddTorrentDialogState();
}

class _AddTorrentDialogState extends State<_AddTorrentDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add magnet link', style: TextStyle(fontSize: 30)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Paste a magnet link, info-hash, HTTP link, or .torrent path',
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GetzyColors.action,
                ),
                onPressed: _pickTorrentFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose .torrent file'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final validation =
                widget.engine.validateNewTorrentSource(_controller.text);
            if (validation != null) {
              setState(() => _errorText = validation);
              return;
            }
            Navigator.of(context).pop(_controller.text);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  Future<void> _pickTorrentFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['torrent'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.first.path;
    if (path == null) {
      return;
    }

    setState(() {
      _controller.text = path;
      _errorText = null;
    });
  }
}

class _TorrentTile extends StatelessWidget {
  const _TorrentTile({
    required this.torrent,
    required this.onToggle,
    required this.onOpenDetails,
  });

  final TorrentTask torrent;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final statusColor = torrent.status == TorrentStatus.blocked
        ? GetzyColors.warning
        : GetzyColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 74,
              child: Center(
                child: Material(
                  color: torrent.status == TorrentStatus.finished
                      ? GetzyColors.elevated
                      : GetzyColors.action,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: torrent.status.isRunning
                        ? 'Pause torrent'
                        : 'Resume torrent',
                    iconSize: 34,
                    color: Colors.white,
                    onPressed: torrent.status.canToggle ? onToggle : null,
                    icon: Icon(torrent.status.isRunning
                        ? Icons.pause
                        : Icons.play_arrow),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    torrent.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GetzyColors.textPrimary,
                      fontSize: 19,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: torrent.progress,
                    minHeight: 4,
                    backgroundColor: GetzyColors.divider,
                    color: GetzyColors.textSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${torrent.status.label}  |  ${(torrent.progress * 100).round()}%',
                    style: TextStyle(color: statusColor, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatBytes(torrent.downloadedBytes)}/${formatBytes(torrent.totalBytes)}'
                    '  |  ${formatSpeed(torrent.downloadSpeedBytes)} down'
                    '  |  ${formatSpeed(torrent.uploadSpeedBytes)} up',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GetzyColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (torrent.blockedReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      torrent.blockedReason!,
                      style: const TextStyle(
                        color: GetzyColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Icon(icon, color: GetzyColors.textSecondary),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
