import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getzy/app/getzy_app.dart';
import 'package:getzy/features/settings/settings_repository.dart';
import 'package:getzy/features/torrents/torrent_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '${Directory.systemTemp.path}/getzy_test';
      },
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await SettingsRepository.instance.saveValue('onboarding_complete', 'true');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/charging'),
      (MethodCall methodCall) async => null,
    );
  });

  setUp(() async {
    TorrentDatabase.instance.reset();
    await SettingsRepository.instance.saveValue('onboarding_complete', 'true');
  });

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpWidget(const GetzyApp());
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('settings screen shows all category titles', (tester) async {
    await openSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Bandwidth'), findsOneWidget);
    expect(find.text('Torrent'), findsOneWidget);
    expect(find.text('Interface'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Privacy & Security'), findsOneWidget);
    expect(find.text('Power management'), findsOneWidget);
    expect(find.text('Scheduling'), findsOneWidget);
    expect(find.text('Feeds'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('storage subpage shows storage options', (tester) async {
    await openSettings(tester);
    await tester.tap(find.text('Storage'));
    await tester.pumpAndSettle();

    expect(find.text('Storage path'), findsOneWidget);
    expect(find.text('Move after download'), findsAtLeast(1));
    expect(find.text('Copy torrent files'), findsAtLeast(1));

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Watch incoming directory'), findsAtLeast(1));
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('bandwidth subpage shows bandwidth controls', (tester) async {
    await openSettings(tester);
    await tester.tap(find.text('Bandwidth'));
    await tester.pumpAndSettle();

    expect(find.text('Maximum download speed'), findsOneWidget);
    expect(find.text('Maximum upload speed'), findsOneWidget);
    expect(
        find.text('Maximum number of connections'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('torrent subpage shows torrent options', (tester) async {
    await openSettings(tester);
    await tester.tap(find.text('Torrent'));
    await tester.pumpAndSettle();

    expect(find.text('Queue new torrents'), findsOneWidget);
    expect(
        find.text('Start torrents after adding'), findsOneWidget);
    expect(find.text('Sequential download'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('interface subpage shows interface options',
      (tester) async {
    await openSettings(tester);
    await tester.tap(find.text('Interface'));
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Compact torrent rows'), findsOneWidget);
    expect(find.text('Show speed in status bar'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('network subpage shows network settings',
      (tester) async {
    await openSettings(tester);
    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();

    expect(find.text('Use random port'), findsOneWidget);
    expect(find.text('Enable DHT'), findsOneWidget);
    expect(find.text('Enable LSD'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Enable UPnP'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('privacy and security subpage shows options',
      (tester) async {
    await openSettings(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy & Security'));
    await tester.pumpAndSettle();

    expect(find.text('VPN only'), findsOneWidget);
    expect(find.text('Encryption'), findsAtLeast(1));

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('Proxy settings'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('power management subpage shows options',
      (tester) async {
    await openSettings(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Power management'));
    await tester.pumpAndSettle();

    expect(find.text('WiFi only'), findsOneWidget);
    expect(find.text('Keep CPU awake'), findsOneWidget);
    expect(find.text('Keep running in background'), findsOneWidget);
    expect(find.text('Shutdown when downloads complete'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('Download/upload only when charging'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('about screen shows legal and privacy info',
      (tester) async {
    await openSettings(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('Getzy'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('about legal dialog opens on tap', (tester) async {
    await openSettings(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Legal'));
    await tester.pumpAndSettle();

    expect(find.text('Legal notice'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });
}
