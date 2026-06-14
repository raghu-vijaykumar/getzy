import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/getzy_app.dart';
import '../../app/getzy_theme.dart';
import '../torrents/torrent_engine.dart';
import 'about_screen.dart';
import 'settings_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.engine});

  final TorrentEngine? engine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(36, 76, 24, 24),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 42),
          for (final category in _settingsCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: ListTile(
                leading: Icon(category.icon, size: 32),
                title: Text(
                  category.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SettingsDetailScreen(category: category, engine: engine),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsDetailScreen extends StatelessWidget {
  const SettingsDetailScreen({
    required this.category,
    super.key,
    this.engine,
  });

  final SettingsCategory category;
  final TorrentEngine? engine;

  @override
  Widget build(BuildContext context) {
    final c = GetzyColors.of(context);
    if (category.title == 'About') {
      return const AboutScreen();
    }

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(36, 76, 36, 24),
        children: [
          Text(category.title, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 54),
          for (final section in category.sections) ...[
            if (section.title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  section.title!,
                  style: TextStyle(
                    color: c.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            for (final row in section.rows)
              _SettingRow(row: row, engine: engine),
            const Divider(height: 36),
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatefulWidget {
  const _SettingRow({required this.row, this.engine});

  final SettingRowData row;
  final TorrentEngine? engine;

  @override
  State<_SettingRow> createState() => _SettingRowState();
}

class _SettingRowState extends State<_SettingRow> {
  late bool _value;
  String _displayValue = '';
  final SettingsRepository _settingsRepo = SettingsRepository.instance;

  @override
  void initState() {
    super.initState();
    _value = widget.row.initialValue;
    _loadSetting();
    _loadDisplayValue();
  }

  Future<void> _loadSetting() async {
    if (!widget.row.hasSwitch || widget.row.settingKey == null) return;
    final saved = await _settingsRepo.loadValue(widget.row.settingKey!);
    if (saved != null && mounted) {
      setState(() => _value = saved == 'true');
    }
  }

  Future<void> _loadDisplayValue() async {
    if (widget.row.opensThemePicker) {
      final saved = await _settingsRepo.loadValue('theme_mode');
      if (saved != null && mounted) {
        final label = switch (saved) {
          'light' => 'Light',
          'system' => 'System',
          _ => 'Dark',
        };
        setState(() => _displayValue = label);
      }
    } else if (widget.row.opensTextScaleSlider) {
      final saved = await _settingsRepo.loadValue('text_scale_factor');
      if (saved != null && mounted) {
        final pct = (double.tryParse(saved) ?? 1.0) * 100;
        setState(() => _displayValue = '${pct.round()}%');
      }
    } else if (widget.row.opensDirectoryPicker && widget.row.pickerSettingKey != null) {
      final saved = await _settingsRepo.loadValue(widget.row.pickerSettingKey!);
      if (saved != null && mounted) {
        setState(() => _displayValue = saved);
      }
    } else if (widget.row.opensTimePicker && widget.row.pickerSettingKey != null) {
      final saved = await _settingsRepo.loadValue(widget.row.pickerSettingKey!);
      if (saved != null && mounted) {
        setState(() => _displayValue = saved);
      } else {
        setState(() => _displayValue = 'Disabled');
      }
    } else if (widget.row.opensNumericSlider && widget.row.pickerSettingKey != null) {
      final saved = await _settingsRepo.loadValue(widget.row.pickerSettingKey!);
      if (saved != null && mounted) {
        setState(() => _displayValue = '$saved${widget.row.sliderSuffix}');
      }
    } else if (widget.row.opensPresetPicker && widget.row.pickerSettingKey != null) {
      final saved = await _settingsRepo.loadValue(widget.row.pickerSettingKey!);
      if (saved != null && mounted && widget.row.presetOptions != null) {
        final match = widget.row.presetOptions!.firstWhere(
          (o) => o.value == saved,
          orElse: () => (label: saved, value: saved),
        );
        setState(() => _displayValue = match.label);
      }
    }
  }

  Future<void> _saveSetting(bool newValue) async {
    if (widget.row.settingKey == null) return;
    await _settingsRepo.saveValue(widget.row.settingKey!, newValue.toString());
    widget.engine?.triggerConstraintCheck();
  }

  @override
  Widget build(BuildContext context) {
    final c = GetzyColors.of(context);
    final row = widget.row;
    final titleColor =
        row.enabled ? c.textPrimary : c.textDisabled;
    final subtitleColor =
        row.enabled ? c.textSecondary : c.textDisabled;

    final isInteractive = row.opensThemePicker ||
        row.opensTextScaleSlider ||
        row.opensDirectoryPicker ||
        row.opensTimePicker ||
        row.opensNumericSlider ||
        row.opensPresetPicker;
    final subtitleText =
        isInteractive ? (_displayValue.isNotEmpty ? _displayValue : row.subtitle) : row.subtitle;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 14,
      enabled: row.enabled,
      title: Text(
        row.title,
        style: TextStyle(
            color: titleColor, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      subtitle: subtitleText == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitleText,
                style:
                    TextStyle(color: subtitleColor, fontSize: 16, height: 1.25),
              ),
            ),
      trailing: row.hasSwitch
          ? Switch(
              value: _value,
              onChanged: row.enabled
                  ? (value) {
                      setState(() => _value = value);
                      _saveSetting(value);
                    }
                  : null,
            )
          : null,
      onTap: row.opensNetworkInterfaceDialog
          ? () => _showNetworkInterfaceDialog(context)
          : row.opensThemePicker
              ? () => _showThemePickerDialog(context)
              : row.opensTextScaleSlider
                  ? () => _showTextScaleSliderDialog(context)
                  : row.opensDirectoryPicker
                      ? () => _showDirectoryPickerDialog(context)
                      : row.opensTimePicker
                          ? () => _showTimePickerDialog(context)
                          : row.opensNumericSlider
                              ? () => _showNumericSliderDialog(context)
                              : row.opensPresetPicker
                                  ? () => _showPresetPickerDialog(context)
                                  : row.hasSwitch && row.enabled
                                      ? () {
                                          final newValue = !_value;
                                          setState(() => _value = newValue);
                                          _saveSetting(newValue);
                                        }
                                      : null,
    );
  }

  Future<void> _showThemePickerDialog(BuildContext context) async {
    final c = GetzyColors.of(context);
    final current = await _settingsRepo.loadValue('theme_mode');
    var selected = switch (current) {
      'light' => 'light',
      'system' => 'system',
      _ => 'dark',
    };

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Theme', style: TextStyle(fontSize: 30)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in [
                    ('dark', 'Dark'),
                    ('light', 'Light'),
                    ('system', 'System'),
                  ])
                    RadioListTile<String>(
                      value: entry.$1,
                      groupValue: selected,
                      activeColor: c.accent,
                      title: Text(entry.$2),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selected = value);
                        }
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      await _settingsRepo.saveValue('theme_mode', result);
      final label = switch (result) {
        'light' => 'Light',
        'system' => 'System',
        _ => 'Dark',
      };
      setState(() => _displayValue = label);
      final appState = context.findAncestorStateOfType<GetzyAppState>();
      appState?.setThemeMode(switch (result) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      });
    }
  }

  Future<void> _showTextScaleSliderDialog(BuildContext context) async {
    final c = GetzyColors.of(context);
    final saved = await _settingsRepo.loadValue('text_scale_factor');
    var factor = double.tryParse(saved ?? '') ?? 1.0;

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Text size', style: TextStyle(fontSize: 30)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(factor * 100).round()}%',
                      style: TextStyle(
                        fontSize: 42 * factor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preview text at this size',
                      style: TextStyle(
                        fontSize: 16 * factor,
                        color: c.textSecondary,
                      ),
                    ),
                    Slider(
                      value: factor,
                      min: 0.7,
                      max: 1.5,
                      divisions: 8,
                      activeColor: c.accent,
                      onChanged: (v) {
                        setDialogState(() => factor = v);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(factor),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      final clamped = result.clamp(0.7, 1.5);
      await _settingsRepo.saveValue(
          'text_scale_factor', clamped.toStringAsFixed(1));
      final pct = (clamped * 100).round();
      setState(() => _displayValue = '$pct%');
      final appState = context.findAncestorStateOfType<GetzyAppState>();
      appState?.setTextScaleFactor(clamped);
    }
  }

  Future<void> _showDirectoryPickerDialog(BuildContext context) async {
    final key = widget.row.pickerSettingKey;
    if (key == null) return;

    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select ${widget.row.title}',
    );
    if (path != null && mounted) {
      await _settingsRepo.saveValue(key, path);
      setState(() => _displayValue = path);
    }
  }

  Future<void> _showTimePickerDialog(BuildContext context) async {
    final key = widget.row.pickerSettingKey;
    if (key == null) return;

    final initial = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Select ${widget.row.title}',
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _settingsRepo.saveValue(key, formatted);
      setState(() => _displayValue = formatted);
    }
  }

  Future<void> _showNumericSliderDialog(BuildContext context) async {
    final c = GetzyColors.of(context);
    final key = widget.row.pickerSettingKey;
    if (key == null) return;

    final saved = await _settingsRepo.loadValue(key);
    var value = double.tryParse(saved ?? '') ?? widget.row.sliderMin;

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(widget.row.title, style: const TextStyle(fontSize: 30)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.round()}${widget.row.sliderSuffix}',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Slider(
                      value: value,
                      min: widget.row.sliderMin,
                      max: widget.row.sliderMax,
                      divisions: widget.row.sliderDivisions,
                      activeColor: c.accent,
                      onChanged: (v) {
                        setDialogState(() => value = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(value),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      final rounded = result.round();
      await _settingsRepo.saveValue(key, rounded.toString());
      setState(() => _displayValue = '$rounded${widget.row.sliderSuffix}');
    }
  }

  Future<void> _showPresetPickerDialog(BuildContext context) async {
    final c = GetzyColors.of(context);
    final key = widget.row.pickerSettingKey;
    final options = widget.row.presetOptions;
    if (key == null || options == null) return;

    final saved = await _settingsRepo.loadValue(key);
    var selected = saved ?? options.first.value;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(widget.row.title, style: const TextStyle(fontSize: 30)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in options)
                      RadioListTile<String>(
                        value: option.value,
                        groupValue: selected,
                        activeColor: c.accent,
                        title: Text(option.label),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selected = value);
                          }
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      await _settingsRepo.saveValue(key, result);
      final match = options.firstWhere(
        (o) => o.value == result,
        orElse: () => (label: result, value: result),
      );
      setState(() => _displayValue = match.label);
    }
  }

  Future<void> _showNetworkInterfaceDialog(BuildContext context) async {
    final c = GetzyColors.of(context);
    final interfaces = [
      'Any interface',
      'rmnet_data0',
      'dummy0',
      'wlan0',
      'r_rmnet_data1',
      'lo',
      'rmnet_data3',
      'vgate0',
      'ifb0',
      'ifb2',
      'ifb1',
    ];
    final saved = await _settingsRepo.loadValue('network_interface');
    var selected = saved ?? interfaces.first;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Network interface',
                  style: TextStyle(fontSize: 30)),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final interface in interfaces)
                      RadioListTile<String>(
                        value: interface,
                        groupValue: selected,
                        activeColor: c.accent,
                        title: Text(interface),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selected = value);
                          }
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      await _settingsRepo.saveValue('network_interface', result);
      setState(() => _displayValue = result);
    }
  }
}

class SettingsCategory {
  const SettingsCategory({
    required this.title,
    required this.icon,
    required this.sections,
  });

  final String title;
  final IconData icon;
  final List<SettingsSection> sections;
}

class SettingsSection {
  const SettingsSection({
    this.title,
    required this.rows,
  });

  final String? title;
  final List<SettingRowData> rows;
}

class SettingRowData {
  const SettingRowData({
    required this.title,
    this.subtitle,
    this.hasSwitch = false,
    this.initialValue = false,
    this.enabled = true,
    this.opensNetworkInterfaceDialog = false,
    this.opensThemePicker = false,
    this.opensTextScaleSlider = false,
    this.opensDirectoryPicker = false,
    this.opensTimePicker = false,
    this.opensNumericSlider = false,
    this.opensPresetPicker = false,
    this.pickerSettingKey,
    this.sliderMin = 5,
    this.sliderMax = 100,
    this.sliderDivisions = 19,
    this.sliderSuffix = '%',
    this.presetOptions,
    this.settingKey,
  });

  final String title;
  final String? subtitle;
  final bool hasSwitch;
  final bool initialValue;
  final bool enabled;
  final bool opensNetworkInterfaceDialog;
  final bool opensThemePicker;
  final bool opensTextScaleSlider;
  final bool opensDirectoryPicker;
  final bool opensTimePicker;
  final bool opensNumericSlider;
  final bool opensPresetPicker;
  final String? pickerSettingKey;
  final double sliderMin;
  final double sliderMax;
  final int sliderDivisions;
  final String sliderSuffix;
  final List<({String label, String value})>? presetOptions;
  final String? settingKey;
}

const _settingsCategories = [
  SettingsCategory(
    title: 'Storage',
    icon: Icons.folder_open,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(
            title: 'Storage path',
            subtitle: '/storage/emulated/0/Download/Getzy',
            opensDirectoryPicker: true,
            pickerSettingKey: 'storage_path',
          ),
        ],
      ),
      SettingsSection(
        title: 'Move after download',
        rows: [
          SettingRowData(
              title: 'Move after download',
              hasSwitch: true,
              settingKey: 'move_after_download'),
          SettingRowData(
            title: 'Move completed to location',
            subtitle: '/storage/emulated/0/Download/Getzy',
            opensDirectoryPicker: true,
            pickerSettingKey: 'move_completed_path',
          ),
        ],
      ),
      SettingsSection(
        title: 'Copy torrent files',
        rows: [
          SettingRowData(
            title: 'Copy torrent files',
            subtitle:
                'Torrent files for magnet links will be copied after metadata is downloaded',
            hasSwitch: true,
            settingKey: 'copy_torrent_files',
          ),
          SettingRowData(
            title: 'Copy torrent files to location',
            subtitle: '/storage/emulated/0/Download/Getzy',
            opensDirectoryPicker: true,
            pickerSettingKey: 'copy_torrent_path',
          ),
        ],
      ),
      SettingsSection(
        title: 'Watch incoming directory',
        rows: [
          SettingRowData(
            title: 'Watch incoming directory',
            subtitle:
                'When Getzy is running, torrent files found in this directory are added automatically.',
            hasSwitch: true,
            settingKey: 'watch_incoming_dir',
          ),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'Bandwidth',
    icon: Icons.router,
    sections: [
      SettingsSection(
        title: 'Bandwidth',
        rows: [
          SettingRowData(
              title: 'Maximum download speed',
              subtitle: 'Unlimited',
              opensPresetPicker: true,
              pickerSettingKey: 'max_download_speed',
              presetOptions: [
                (label: 'Unlimited', value: '0'),
                (label: '100 KB/s', value: '100'),
                (label: '500 KB/s', value: '500'),
                (label: '1 MB/s', value: '1024'),
                (label: '5 MB/s', value: '5120'),
                (label: '10 MB/s', value: '10240'),
              ]),
          SettingRowData(
              title: 'Maximum upload speed',
              subtitle: 'Unlimited',
              opensPresetPicker: true,
              pickerSettingKey: 'max_upload_speed',
              presetOptions: [
                (label: 'Unlimited', value: '0'),
                (label: '100 KB/s', value: '100'),
                (label: '500 KB/s', value: '500'),
                (label: '1 MB/s', value: '1024'),
                (label: '5 MB/s', value: '5120'),
              ]),
        ],
      ),
      SettingsSection(
        title: 'Connection settings',
        rows: [
          SettingRowData(
              title: 'Maximum number of connections',
              subtitle: '200',
              opensNumericSlider: true,
              pickerSettingKey: 'max_connections',
              sliderMin: 1,
              sliderMax: 1000,
              sliderDivisions: 999,
              sliderSuffix: ''),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'Torrent',
    icon: Icons.water_drop,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(
              title: 'Queue new torrents',
              hasSwitch: true,
              initialValue: true,
              settingKey: 'queue_new_torrents'),
          SettingRowData(
              title: 'Start torrents after adding',
              hasSwitch: true,
              settingKey: 'start_after_adding'),
          SettingRowData(
              title: 'Sequential download',
              hasSwitch: true,
              settingKey: 'sequential_download'),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'Interface',
    icon: Icons.tune,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(
              title: 'Theme',
              subtitle: 'Dark',
              opensThemePicker: true),
          SettingRowData(
              title: 'Text size',
              subtitle: '100%',
              opensTextScaleSlider: true),
          SettingRowData(
              title: 'Compact torrent rows',
              hasSwitch: true,
              initialValue: true,
              settingKey: 'compact_rows'),
          SettingRowData(
              title: 'Show speed in status bar',
              hasSwitch: true,
              settingKey: 'show_status_speed'),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'Network',
    icon: Icons.wifi,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(
            title: 'Use random port',
            subtitle: 'A random port will be assigned from range 49152-65535',
            hasSwitch: true,
            initialValue: true,
            settingKey: 'random_port',
          ),
          SettingRowData(
              title: 'Set a port number',
              subtitle: '55623',
              opensNumericSlider: true,
              pickerSettingKey: 'listening_port',
              sliderMin: 1024,
              sliderMax: 65535,
              sliderDivisions: 64511,
              sliderSuffix: ''),
        ],
      ),
      SettingsSection(
        title: 'Network extras',
        rows: [
          SettingRowData(
              title: 'Enable DHT', hasSwitch: true, initialValue: true, settingKey: 'enable_dht'),
          SettingRowData(
              title: 'Enable LSD', hasSwitch: true, initialValue: true, settingKey: 'enable_lsd'),
          SettingRowData(
              title: 'Enable UPnP', hasSwitch: true, initialValue: true, settingKey: 'enable_upnp'),
          SettingRowData(
              title: 'Enable NAT-PMP', hasSwitch: true, initialValue: true, settingKey: 'enable_nat_pmp'),
          SettingRowData(
            title: 'Enable peer exchange',
            subtitle:
                'This setting will be applied when you shutdown and restart Getzy.',
            hasSwitch: true,
            initialValue: true,
            settingKey: 'enable_pex',
          ),
          SettingRowData(
              title: 'Always contact all trackers', hasSwitch: true, settingKey: 'contact_all_trackers'),
          SettingRowData(
              title: 'Enable uTP', hasSwitch: true, settingKey: 'enable_utp'),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'Privacy & Security',
    icon: Icons.shield_outlined,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(
            title: 'VPN only',
            subtitle:
                'If enabled, torrents will download and upload only if a VPN is connected',
            hasSwitch: true,
            settingKey: 'vpn_only',
          ),
        ],
      ),
      SettingsSection(
        title: 'Encryption',
        rows: [
          SettingRowData(
              title: 'Incoming connections',
              subtitle: 'Enabled',
              opensPresetPicker: true,
              pickerSettingKey: 'encryption_incoming',
              presetOptions: [
                (label: 'Enabled', value: 'enabled'),
                (label: 'Disabled', value: 'disabled'),
              ]),
          SettingRowData(
              title: 'Outgoing connections',
              subtitle: 'Enabled',
              opensPresetPicker: true,
              pickerSettingKey: 'encryption_outgoing',
              presetOptions: [
                (label: 'Enabled', value: 'enabled'),
                (label: 'Disabled', value: 'disabled'),
              ]),
          SettingRowData(
              title: 'Encryption level',
              subtitle: 'Both',
              opensPresetPicker: true,
              pickerSettingKey: 'encryption_level',
              presetOptions: [
                (label: 'Forced', value: 'forced'),
                (label: 'Enabled', value: 'enabled'),
                (label: 'Disabled', value: 'disabled'),
              ]),
        ],
      ),
      SettingsSection(
        title: 'Proxy settings',
        rows: [
          SettingRowData(
              title: 'Proxy settings',
              subtitle: '(None)',
              opensPresetPicker: true,
              pickerSettingKey: 'proxy_type',
              presetOptions: [
                (label: '(None)', value: 'none'),
                (label: 'SOCKS4', value: 'socks4'),
                (label: 'SOCKS5', value: 'socks5'),
                (label: 'HTTP/HTTPS', value: 'http'),
              ]),
        ],
      ),
      SettingsSection(
        title: 'IP filtering',
        rows: [
          SettingRowData(
            title: 'Enable IP filtering',
            subtitle:
                'Using IP filtering increases memory usage. Depending on file size, the filter may take time to apply.',
            hasSwitch: true,
            settingKey: 'enable_ip_filter',
          ),
          SettingRowData(
              title: 'IP filter file (.dat, .p2p, .p2b)',
              subtitle: 'Not set',
              opensDirectoryPicker: true,
              pickerSettingKey: 'ip_filter_path'),
        ],
      ),
      SettingsSection(
        title: 'Privacy settings',
        rows: [
          SettingRowData(
            title: 'Allow usage statistics',
            subtitle:
                'No personal data will be collected. Disabled by default in Getzy.',
            hasSwitch: true,
            settingKey: 'allow_usage_stats',
          ),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'Power management',
    icon: Icons.battery_charging_full,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(
            title: 'WiFi only',
            subtitle:
                'Torrents will download and upload only if WiFi is connected',
            hasSwitch: true,
            initialValue: true,
            settingKey: 'wifi_only',
          ),
          SettingRowData(
            title: 'Shutdown when downloads complete',
            subtitle:
                'The app will shutdown when all downloads have completed in the background.',
            hasSwitch: true,
            settingKey: 'shutdown_when_complete',
          ),
          SettingRowData(
            title: 'Keep running in background',
            subtitle:
                'Useful when RSS feeds need to be refreshed automatically.',
            hasSwitch: true,
            settingKey: 'keep_running_background',
          ),
          SettingRowData(
            title: 'Keep CPU awake',
            subtitle:
                'Use if download speed reduces when the screen turns off.',
            hasSwitch: true,
            settingKey: 'keep_cpu_awake',
          ),
        ],
      ),
      SettingsSection(
        title: 'Battery settings',
        rows: [
          SettingRowData(
            title: 'Download/upload only when charging',
            subtitle: 'All torrents will pause when not connected to charger.',
            hasSwitch: true,
            settingKey: 'charging_only',
          ),
          SettingRowData(
            title: 'Enable battery limit',
            subtitle:
                'All torrents pause if the battery level goes below the specified limit.',
            hasSwitch: true,
            settingKey: 'battery_limit',
          ),
          SettingRowData(
            title: 'Battery level limit',
            subtitle: '25%',
            opensNumericSlider: true,
            pickerSettingKey: 'battery_level',
            sliderMin: 5,
            sliderMax: 100,
            sliderDivisions: 19,
            sliderSuffix: '%',
          ),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'Scheduling',
    icon: Icons.schedule,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(
            title: 'Scheduled start time',
            subtitle: 'Disabled',
            opensTimePicker: true,
            pickerSettingKey: 'scheduled_start_time',
          ),
          SettingRowData(
            title: 'Scheduled shutdown time',
            subtitle: 'Disabled',
            opensTimePicker: true,
            pickerSettingKey: 'scheduled_shutdown_time',
          ),
          SettingRowData(
              title: 'Run only once', hasSwitch: true, settingKey: 'run_once'),
          SettingRowData(
              title: 'Resume all', hasSwitch: true, settingKey: 'resume_all'),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'Feeds',
    icon: Icons.rss_feed,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(
            title: 'Feed refresh interval',
            subtitle: 'Current value is 60',
            opensPresetPicker: true,
            pickerSettingKey: 'feed_refresh_interval_minutes',
            presetOptions: [
              (label: 'Manual', value: '0'),
              (label: '15 minutes', value: '15'),
              (label: '30 minutes', value: '30'),
              (label: '1 hour', value: '60'),
              (label: '2 hours', value: '120'),
              (label: '6 hours', value: '360'),
              (label: '12 hours', value: '720'),
              (label: '24 hours', value: '1440'),
            ],
          ),
          SettingRowData(
            title: 'Remove old items',
            subtitle: 'Old items will be removed from feeds after every 5 days',
            opensPresetPicker: true,
            pickerSettingKey: 'feed_cleanup_days',
            presetOptions: [
              (label: 'Never', value: '0'),
              (label: '1 day', value: '1'),
              (label: '3 days', value: '3'),
              (label: '5 days', value: '5'),
              (label: '7 days', value: '7'),
              (label: '14 days', value: '14'),
              (label: '30 days', value: '30'),
            ],
          ),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'Advanced',
    icon: Icons.settings_input_component,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(
            title: 'Network interface',
            subtitle: 'Any interface',
            opensNetworkInterfaceDialog: true,
          ),
        ],
      ),
    ],
  ),
  SettingsCategory(
    title: 'About',
    icon: Icons.info_outline,
    sections: [
      SettingsSection(
        rows: [
          SettingRowData(title: 'About', subtitle: 'About Getzy'),
          SettingRowData(
              title: 'Help in translation',
              subtitle: 'Help translate Getzy into your language'),
          SettingRowData(
              title: 'Legal',
              subtitle:
                  'Use Getzy only for content you have rights to download.'),
          SettingRowData(
              title: 'Privacy policy', subtitle: 'No analytics or ads in v1.'),
        ],
      ),
    ],
  ),
];
