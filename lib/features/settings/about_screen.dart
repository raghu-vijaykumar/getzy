import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/getzy_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(36, 76, 36, 24),
        children: [
          const Text('Getzy', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 12),
          const Text(
            'Version 1.0.0',
            style: TextStyle(
              color: GetzyColors.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 42),
          _InfoRow(
            icon: Icons.description,
            title: 'Legal',
            subtitle: 'Use Getzy only for content you have rights to download.',
            onTap: () => _showAssetContent(
                context, 'Legal notice', 'assets/texts/legal.md'),
          ),
          const Divider(height: 36),
          _InfoRow(
            icon: Icons.privacy_tip,
            title: 'Privacy policy',
            subtitle: 'No analytics or ads in v1.',
            onTap: () => _showAssetContent(
                context, 'Privacy policy', 'assets/texts/privacy.md'),
          ),
          const Divider(height: 36),
          _InfoRow(
            icon: Icons.translate,
            title: 'Help in translation',
            subtitle: 'Help translate Getzy into your language',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showAssetContent(
      BuildContext context, String title, String assetPath) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<String>(
          future: rootBundle.loadString(assetPath),
          builder: (context, snapshot) {
            final content = snapshot.hasData
                ? snapshot.data!
                : 'Could not load content.';
            return AlertDialog(
              title: Text(title, style: const TextStyle(fontSize: 26)),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: GetzyColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 32),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: GetzyColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
