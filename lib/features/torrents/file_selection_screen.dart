import 'package:flutter/material.dart';

import 'torrent_models.dart';

class FileSelectionScreen extends StatefulWidget {
  const FileSelectionScreen({
    super.key,
    required this.files,
    required this.torrentName,
    this.onConfirm,
    this.onCancel,
  });

  final List<TorrentFile> files;
  final String torrentName;
  final void Function(List<TorrentFile> selectedFiles)? onConfirm;
  final VoidCallback? onCancel;

  @override
  State<FileSelectionScreen> createState() => _FileSelectionScreenState();
}

class _FileSelectionScreenState extends State<FileSelectionScreen> {
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.generate(widget.files.length, (_) => true);
  }

  bool get _allSelected => _selected.every((s) => s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select files to download'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                final select = !_allSelected;
                for (var i = 0; i < _selected.length; i++) {
                  _selected[i] = select;
                }
              });
            },
            child: Text(_allSelected ? 'Deselect all' : 'Select all'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.torrentName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.files.length,
              itemBuilder: (context, index) {
                final file = widget.files[index];
                return CheckboxListTile(
                  value: _selected[index],
                  onChanged: (value) {
                    setState(() => _selected[index] = value ?? false);
                  },
                  title: Text(file.path),
                  subtitle: Text(formatBytes(file.lengthBytes)),
                  secondary: Icon(
                    _selected[index] ? Icons.check_circle : Icons.radio_button_unchecked,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onCancel?.call(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final selectedFiles = <TorrentFile>[];
                    for (var i = 0; i < widget.files.length; i++) {
                      selectedFiles.add(TorrentFile(
                        path: widget.files[i].path,
                        lengthBytes: widget.files[i].lengthBytes,
                        priority: widget.files[i].priority,
                        progress: widget.files[i].progress,
                        selected: _selected[i],
                      ));
                    }
                    widget.onConfirm?.call(selectedFiles);
                  },
                  child: Text('Start download (${_selected.where((s) => s).length} files)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
