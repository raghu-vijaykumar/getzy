import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_repository.dart';
import '../features/torrents/real_torrent_engine.dart';
import '../features/torrents/torrent_engine.dart';
import '../features/torrents/torrent_home_screen.dart';
import 'getzy_theme.dart';

class GetzyApp extends StatefulWidget {
  const GetzyApp({super.key, this.engine});

  final TorrentEngine? engine;

  @override
  State<GetzyApp> createState() => GetzyAppState();
}

class GetzyAppState extends State<GetzyApp> {
  late final TorrentEngine _engine;
  static const MethodChannel _channel = MethodChannel('getzy/torrent_engine');
  bool? _onboardingComplete;
  ThemeMode _themeMode = ThemeMode.dark;
  double _textScaleFactor = 1.0;

  TorrentEngine get engine => _engine;
  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    SettingsRepository.instance.saveValue('theme_mode', mode.name);
    if (mounted) setState(() {});
  }

  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor;
    SettingsRepository.instance.saveValue('text_scale_factor', factor.toStringAsFixed(1));
    if (mounted) setState(() {});
  }

  late final bool _ownsEngine;

  @override
  void initState() {
    super.initState();
    _ownsEngine = widget.engine == null;
    _engine = widget.engine ?? RealTorrentEngine();
    _engine.initialize();
    _channel.setMethodCallHandler(_handleNativeCall);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await Future.wait([
      _checkOnboarding(),
      _loadThemeMode(),
      _loadTextScaleFactor(),
    ]);
  }

  Future<void> _checkOnboarding() async {
    try {
      final saved =
          await SettingsRepository.instance.loadValue('onboarding_complete');
      if (mounted) {
        setState(() => _onboardingComplete = saved == 'true');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _onboardingComplete = true);
      }
    }
  }

  Future<void> _loadThemeMode() async {
    try {
      final saved = await SettingsRepository.instance.loadValue('theme_mode');
      if (saved != null && mounted) {
        setState(() {
          _themeMode = ThemeMode.values.firstWhere(
            (e) => e.name == saved,
            orElse: () => ThemeMode.dark,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadTextScaleFactor() async {
    try {
      final saved =
          await SettingsRepository.instance.loadValue('text_scale_factor');
      if (saved != null && mounted) {
        final parsed = double.tryParse(saved);
        if (parsed != null) {
          setState(() => _textScaleFactor = parsed.clamp(0.7, 1.5));
        }
      }
    } catch (_) {}
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'notificationAction') {
      final action = call.arguments as String?;
      if (action != null) {
        _engine.handleNotificationAction(action);
      }
    }
    return null;
  }

  @override
  void dispose() {
    if (_ownsEngine) {
      _engine.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return MaterialApp(
        title: 'Getzy',
        debugShowCheckedModeBanner: false,
        theme: buildDarkTheme(),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Getzy',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_textScaleFactor),
          ),
          child: child!,
        );
      },
      home: _onboardingComplete == true
          ? TorrentHomeScreen(engine: _engine)
          : OnboardingScreen(
              homeBuilder: (_) => TorrentHomeScreen(engine: _engine),
            ),
    );
  }
}
