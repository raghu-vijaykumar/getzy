import 'package:flutter/material.dart';

import '../../app/getzy_theme.dart';

class FileTreeEntry {
  final String name;
  final String? fullPath;
  final List<FileTreeEntry> children;
  bool isExpanded;
  final int? percentage;
  final String? progressLabel;

  FileTreeEntry({
    required this.name,
    this.fullPath,
    List<FileTreeEntry>? children,
    this.isExpanded = false,
    this.percentage,
    this.progressLabel,
  }) : children = children ?? [];

  bool get isDirectory => children.isNotEmpty;
}

List<FileTreeEntry> buildFileTree(List<String> paths) {
  final rootMap = <String, Map<String, dynamic>>{};

  for (final path in paths) {
    final parts = path.split('/');
    var current = rootMap;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final isLast = i == parts.length - 1;

      if (isLast) {
        current[part] = {'type': 'file', 'path': path};
      } else {
        current[part] ??= {
          'type': 'dir',
          'children': <String, Map<String, dynamic>>{},
        };
        current = current[part]!['children']
            as Map<String, Map<String, dynamic>>;
      }
    }
  }

  return _buildEntries(rootMap);
}

List<FileTreeEntry> _buildEntries(Map<String, Map<String, dynamic>> map) {
  final entries = <FileTreeEntry>[];
  final keys = map.keys.toList()..sort();

  for (final key in keys) {
    final value = map[key]!;
    if (value['type'] == 'file') {
      entries.add(FileTreeEntry(
        name: key,
        fullPath: value['path'] as String,
      ));
    } else {
      final children = _buildEntries(
          value['children'] as Map<String, Map<String, dynamic>>);
      entries.add(FileTreeEntry(
        name: key,
        children: children,
      ));
    }
  }

  return entries;
}

class FlatEntry {
  final FileTreeEntry entry;
  final int depth;
  FlatEntry(this.entry, this.depth);
}

class FileTreeWidget extends StatefulWidget {
  final List<FileTreeEntry> roots;
  final ValueChanged<String>? onFileTap;

  const FileTreeWidget({
    super.key,
    required this.roots,
    this.onFileTap,
  });

  @override
  State<FileTreeWidget> createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends State<FileTreeWidget> {
  late List<FlatEntry> _flatEntries;
  int _totalFiles = 0;

  @override
  void initState() {
    super.initState();
    _flatten();
    _countFiles();
  }

  @override
  void didUpdateWidget(FileTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _flatten();
    _countFiles();
  }

  void _countFiles() {
    int count = 0;
    void walk(List<FileTreeEntry> entries) {
      for (final entry in entries) {
        if (!entry.isDirectory) {
          count++;
        } else {
          walk(entry.children);
        }
      }
    }
    walk(widget.roots);
    _totalFiles = count;
  }

  void _flatten() {
    _flatEntries = [];
    void walk(List<FileTreeEntry> entries, int depth) {
      for (final entry in entries) {
        _flatEntries.add(FlatEntry(entry, depth));
        if (entry.isDirectory && entry.isExpanded) {
          walk(entry.children, depth + 1);
        }
      }
    }
    walk(widget.roots, 0);
  }

  void _toggleExpand(FileTreeEntry entry) {
    setState(() {
      entry.isExpanded = !entry.isExpanded;
      _flatten();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = GetzyColors.of(context);

    if (_flatEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('$_totalFiles files',
            style: TextStyle(color: c.textSecondary, fontSize: 14)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_totalFiles files',
            style: TextStyle(color: c.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        ...List.generate(_flatEntries.length, (index) {
          final flat = _flatEntries[index];
          final entry = flat.entry;
          final isDir = entry.isDirectory;

          return Padding(
            padding: EdgeInsets.only(left: flat.depth * 24.0),
            child: Card(
              color: c.surface,
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: isDir
                  ? ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(
                        entry.isExpanded
                            ? Icons.folder_open
                            : Icons.folder,
                        color: c.accent,
                        size: 20,
                      ),
                      title: Text(entry.name,
                          style: const TextStyle(fontSize: 14)),
                      trailing: Icon(
                        entry.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: c.textSecondary,
                        size: 20,
                      ),
                      onTap: () => _toggleExpand(entry),
                    )
                  : ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(Icons.insert_drive_file,
                          color: c.textSecondary, size: 18),
                      title: Text(entry.name,
                          style: const TextStyle(fontSize: 14)),
                      trailing: entry.percentage != null
                          ? SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value:
                                            (entry.percentage ?? 0) / 100,
                                        minHeight: 6,
                                        backgroundColor: c.divider,
                                        color: c.accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${entry.percentage}%',
                                    style: TextStyle(
                                        color: c.textSecondary,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : null,
                      onTap: entry.fullPath != null &&
                              widget.onFileTap != null
                          ? () => widget.onFileTap!(entry.fullPath!)
                          : null,
                    ),
            ),
          );
        }),
      ],
    );
  }
}
