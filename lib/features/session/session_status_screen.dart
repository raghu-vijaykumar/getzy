import 'package:flutter/material.dart';

import '../../app/getzy_theme.dart';
import '../torrents/torrent_engine.dart';
import '../torrents/torrent_models.dart';

class SessionStatusScreen extends StatelessWidget {
  const SessionStatusScreen({required this.engine, super.key});

  final TorrentEngine engine;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Session status'),
            actions: [
              IconButton(
                tooltip: 'Session settings',
                onPressed: () {},
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            children: [
              const _SectionTitle('TOTAL TRANSFER SPEEDS'),
              _DualMetricRow(
                left: '${formatSpeed(engine.downloadSpeedBytes)} down',
                right: '${formatSpeed(engine.uploadSpeedBytes)} up',
              ),
              const Divider(height: 40),
              const _SectionTitle('INCOMING CONNECTIONS'),
              const ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.warning, color: GetzyColors.warning),
                title: Text('No incoming connections with port 45547'),
              ),
              const Divider(height: 40),
              const _SectionTitle('NUMBER OF TORRENTS'),
              _DualMetricRow(
                left: '${engine.torrents.length}',
                right: 'Finished ${engine.finishedTorrentCount}',
              ),
              const Divider(height: 40),
              const _SectionTitle('DATA TRANSFERRED THIS SESSION'),
              const _DualMetricRow(left: '23.6 KB down', right: '62.3 KB up'),
              const Divider(height: 40),
              const _SectionTitle('DATA TRANSFERRED ALL TIME'),
              const _DualMetricRow(left: '867.2 GB down', right: '50.7 GB up'),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        label,
        style: const TextStyle(
          color: GetzyColors.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _DualMetricRow extends StatelessWidget {
  const _DualMetricRow({required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style:
                const TextStyle(color: GetzyColors.textSecondary, fontSize: 22),
          ),
        ),
        Text(
          right,
          style:
              const TextStyle(color: GetzyColors.textSecondary, fontSize: 22),
        ),
      ],
    );
  }
}
