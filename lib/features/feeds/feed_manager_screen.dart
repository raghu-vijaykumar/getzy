import 'package:flutter/material.dart';

import '../../app/getzy_theme.dart';
import '../torrents/torrent_engine.dart';
import 'feed_models.dart';
import 'feed_repository.dart';

class FeedManagerScreen extends StatefulWidget {
  const FeedManagerScreen({required this.engine, super.key});

  final TorrentEngine engine;

  @override
  State<FeedManagerScreen> createState() => _FeedManagerScreenState();
}

class _FeedManagerScreenState extends State<FeedManagerScreen> {
  final FeedRepository _repository = FeedRepository.instance;
  List<RssFeed> _feeds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    try {
      final feeds = await _repository.loadFeeds();
      setState(() {
        _feeds = feeds.isEmpty
            ? [
                RssFeed(
                  name: 'Linux releases',
                  url: 'https://example.com/linux-release-feed.xml',
                  autoDownload: false,
                  lastRefreshed:
                      DateTime.now().subtract(const Duration(hours: 5)),
                ),
              ]
            : feeds;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshFeeds() async {
    final messages = <String>[];
    for (var index = 0; index < _feeds.length; index++) {
      final feed = _feeds[index];
      try {
        await _repository.refreshFeed(feed, widget.engine);
        _feeds[index] = feed.copyWith(lastRefreshed: DateTime.now());
        messages.add('${feed.name} refreshed');
      } catch (error) {
        messages.add('${feed.name} failed');
      }
    }
    setState(() {});
    _showSnackBar(messages.join(', '));
  }

  Future<void> _removeFeed(int index) async {
    final removed = _feeds[index];
    setState(() {
      _feeds.removeAt(index);
    });
    try {
      await _repository.removeFeed(removed.url);
    } catch (_) {}
    _showSnackBar('Removed ${removed.name}');
  }

  @override
  Widget build(BuildContext context) {
    final c = GetzyColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed manager'),
        actions: [
          IconButton(
            tooltip: 'Add feed',
            onPressed: _showAddFeedDialog,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh feeds',
            onPressed: _refreshFeeds,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
              : _feeds.isEmpty
                  ? Center(
                      child: Text(
                        'No feeds configured',
                        style: TextStyle(
                            color: c.textSecondary, fontSize: 18),
                      ),
                    )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  itemCount: _feeds.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final feed = _feeds[index];
                    return Dismissible(
                      key: ValueKey(feed.url),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _removeFeed(index),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.rss_feed),
                        title: Text(feed.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(feed.url),
                            const SizedBox(height: 4),
                            Text(
                              'Last refreshed: ${feed.lastRefreshedString}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        trailing: feed.autoDownload
                            ? Icon(Icons.download_for_offline,
                                color: c.accent)
                            : null,
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showAddFeedDialog() async {
    final feed = await showDialog<RssFeed>(
      context: context,
      builder: (context) => const _AddFeedDialog(),
    );

    if (feed != null) {
      setState(() => _feeds.add(feed));
      try {
        await _repository.addFeed(feed);
      } catch (_) {}
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AddFeedDialog extends StatefulWidget {
  const _AddFeedDialog();

  @override
  State<_AddFeedDialog> createState() => _AddFeedDialogState();
}

class _AddFeedDialogState extends State<_AddFeedDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _autoDownload = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add feed', style: TextStyle(fontSize: 30)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NAME', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TextField(controller: _nameController, autofocus: true),
              const SizedBox(height: 24),
              const Text('LINK TO RSS FEED',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TextField(controller: _urlController),
              const SizedBox(height: 20),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _autoDownload,
                title: const Text(
                    'Automatically download torrents published in this feed'),
                onChanged: (value) => setState(() {
                  _autoDownload = value ?? false;
                }),
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_errorText!,
                      style: TextStyle(color: GetzyColors.of(context).warning)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('OK'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty || !url.toLowerCase().startsWith('http')) {
      setState(() => _errorText = 'Enter a name and RSS URL.');
      return;
    }

    Navigator.of(context).pop(RssFeed(
      name: name,
      url: url,
      autoDownload: _autoDownload,
      lastRefreshed: DateTime.now(),
    ));
  }
}
