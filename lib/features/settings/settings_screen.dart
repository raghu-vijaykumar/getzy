import 'package:flutter/material.dart';

import '../../app/getzy_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                      builder: (_) => SettingsDetailScreen(category: category),
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
  const SettingsDetailScreen({required this.category, super.key});

  final SettingsCategory category;

  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(
                    color: GetzyColors.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            for (final row in section.rows) _SettingRow(row: row),
            const Divider(height: 36),
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatefulWidget {
  const _SettingRow({required this.row});

  final SettingRowData row;

  @override
  State<_SettingRow> createState() => _SettingRowState();
}

class _SettingRowState extends State<_SettingRow> {
  late bool _value = widget.row.initialValue;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final titleColor =
        row.enabled ? GetzyColors.textPrimary : GetzyColors.textDisabled;
    final subtitleColor =
        row.enabled ? GetzyColors.textSecondary : GetzyColors.textDisabled;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 14,
      enabled: row.enabled,
      title: Text(
        row.title,
        style: TextStyle(
            color: titleColor, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      subtitle: row.subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                row.subtitle!,
                style:
                    TextStyle(color: subtitleColor, fontSize: 16, height: 1.25),
              ),
            ),
      trailing: row.hasSwitch
          ? Switch(
              value: _value,
              onChanged: row.enabled
                  ? (value) => setState(() => _value = value)
                  : null,
            )
          : null,
      onTap: row.opensNetworkInterfaceDialog
          ? () => _showNetworkInterfaceDialog(context)
          : row.hasSwitch && row.enabled
              ? () => setState(() => _value = !_value)
              : null,
    );
  }

  Future<void> _showNetworkInterfaceDialog(BuildContext context) {
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
    var selected = interfaces.first;

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        activeColor: GetzyColors.accent,
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
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
  });

  final String title;
  final String? subtitle;
  final bool hasSwitch;
  final bool initialValue;
  final bool enabled;
  final bool opensNetworkInterfaceDialog;
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
          ),
        ],
      ),
      SettingsSection(
        title: 'Move after download',
        rows: [
          SettingRowData(title: 'Move after download', hasSwitch: true),
          SettingRowData(
            title: 'Move completed to location',
            subtitle: '/storage/emulated/0/Download/Getzy',
            enabled: false,
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
          ),
          SettingRowData(
            title: 'Copy torrent files to location',
            subtitle: '/storage/emulated/0/Download/Getzy',
            enabled: false,
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
              title: 'Maximum download speed', subtitle: 'Unlimited down'),
          SettingRowData(
              title: 'Maximum upload speed', subtitle: 'Unlimited up'),
        ],
      ),
      SettingsSection(
        title: 'Connection settings',
        rows: [
          SettingRowData(
              title: 'Maximum number of connections',
              subtitle: 'Current value is 200'),
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
              title: 'Queue new torrents', hasSwitch: true, initialValue: true),
          SettingRowData(title: 'Start torrents after adding', hasSwitch: true),
          SettingRowData(title: 'Sequential download', hasSwitch: true),
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
          SettingRowData(title: 'Theme', subtitle: 'Dark'),
          SettingRowData(
              title: 'Compact torrent rows',
              hasSwitch: true,
              initialValue: true),
          SettingRowData(title: 'Show speed in status bar', hasSwitch: true),
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
          ),
          SettingRowData(
              title: 'Set a port number',
              subtitle: 'Current value is 55623',
              enabled: false),
        ],
      ),
      SettingsSection(
        title: 'Network extras',
        rows: [
          SettingRowData(
              title: 'Enable DHT', hasSwitch: true, initialValue: true),
          SettingRowData(
              title: 'Enable LSD', hasSwitch: true, initialValue: true),
          SettingRowData(
              title: 'Enable UPnP', hasSwitch: true, initialValue: true),
          SettingRowData(
              title: 'Enable NAT-PMP', hasSwitch: true, initialValue: true),
          SettingRowData(
            title: 'Enable peer exchange',
            subtitle:
                'This setting will be applied when you shutdown and restart Getzy.',
            hasSwitch: true,
            initialValue: true,
          ),
          SettingRowData(title: 'Always contact all trackers', hasSwitch: true),
          SettingRowData(title: 'Enable uTP', hasSwitch: true),
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
          ),
        ],
      ),
      SettingsSection(
        title: 'Encryption',
        rows: [
          SettingRowData(title: 'Incoming connections', subtitle: 'Enabled'),
          SettingRowData(title: 'Outgoing connections', subtitle: 'Enabled'),
          SettingRowData(title: 'Encryption level', subtitle: 'Both'),
        ],
      ),
      SettingsSection(
        title: 'Proxy settings',
        rows: [
          SettingRowData(title: 'Proxy settings', subtitle: '(None)'),
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
          ),
          SettingRowData(
              title: 'IP filter file (.dat, .p2p, .p2b)',
              subtitle: 'Not set',
              enabled: false),
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
          ),
          SettingRowData(
            title: 'Shutdown when downloads complete',
            subtitle:
                'The app will shutdown when all downloads have completed in the background.',
            hasSwitch: true,
          ),
          SettingRowData(
            title: 'Keep running in background',
            subtitle:
                'Useful when RSS feeds need to be refreshed automatically.',
            hasSwitch: true,
          ),
          SettingRowData(
            title: 'Keep CPU awake',
            subtitle:
                'Use if download speed reduces when the screen turns off.',
            hasSwitch: true,
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
          ),
          SettingRowData(
            title: 'Enable battery limit',
            subtitle:
                'All torrents pause if the battery level goes below the specified limit.',
            hasSwitch: true,
          ),
          SettingRowData(
              title: 'Battery level limit', subtitle: '25%', enabled: false),
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
          SettingRowData(title: 'Scheduled start time', subtitle: 'Disabled'),
          SettingRowData(
              title: 'Scheduled shutdown time', subtitle: 'Disabled'),
          SettingRowData(
              title: 'Run only once', hasSwitch: true, enabled: false),
          SettingRowData(title: 'Resume all', hasSwitch: true, enabled: false),
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
              title: 'Feed refresh interval', subtitle: 'Current value is 60'),
          SettingRowData(
            title: 'Remove old items',
            subtitle: 'Old items will be removed from feeds after every 5 days',
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
