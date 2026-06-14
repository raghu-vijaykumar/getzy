import 'package:flutter/material.dart';

import '../../app/getzy_theme.dart';
import '../settings/settings_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.homeBuilder});

  final WidgetBuilder homeBuilder;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final c = GetzyColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Getzy',
                style: TextStyle(fontSize: 42, color: c.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Torrent Downloader',
                style: TextStyle(
                  fontSize: 20,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Legal notice',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Getzy is a torrent downloader. Use Getzy only for '
                      'downloading content you have the legal right to access. '
                      'The developers assume no liability for misuse of this '
                      'application.\n\n'
                      'Getzy does not host, index, or promote any copyrighted '
                      'content. Torrent technology is a neutral protocol — '
                      'please comply with applicable laws in your jurisdiction.',
                      style: TextStyle(
                        fontSize: 16,
                        color: c.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Privacy policy',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Getzy does not collect, store, or transmit any personal '
                      'information.\n\n'
                      'No analytics, crash reporting, or telemetry is included.\n\n'
                      'All torrent data, settings, and RSS feeds are stored '
                      'locally on your device.\n\n'
                      'Getzy does not connect to any third-party servers except:\n'
                      '  • Tracker URLs specified in torrents you add\n'
                      '  • RSS feed URLs you configure\n'
                      '  • HTTP/HTTPS torrent sources you provide\n\n'
                      'No usage statistics are collected.',
                      style: TextStyle(
                        fontSize: 16,
                        color: c.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _accepted,
                    activeColor: c.accent,
                    onChanged: (value) =>
                        setState(() => _accepted = value ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _accepted = !_accepted),
                      child: Text(
                        'I understand that I am responsible for complying with '
                        'applicable laws when using Getzy.',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _accepted ? c.action : c.elevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: _accepted ? _onAccept : null,
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAccept() async {
    await SettingsRepository.instance.saveValue('onboarding_complete', 'true');
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => widget.homeBuilder(context),
      ),
    );
  }
}
