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
        return '${Directory.systemTemp.path}/getzy_integration_test';
      },
    );
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
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    TorrentDatabase.instance.reset();
    await SettingsRepository.instance.saveValue('onboarding_complete', 'true');
  });

  testWidgets('app startup renders home screen with torrents', (tester) async {
    await tester.pumpWidget(const GetzyApp());
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Getzy'), findsOneWidget);
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('QUEUED'), findsOneWidget);
    expect(find.text('FINISHED'), findsOneWidget);
    expect(find.text('Ubuntu Desktop 24.04 LTS'), findsOneWidget);
    expect(find.text('Add torrent'), findsOneWidget);
  });

  testWidgets('add torrent via info hash shows in list', (tester) async {
    await tester.pumpWidget(const GetzyApp());
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    await tester.tap(find.text('Add torrent'));
    await tester.pumpAndSettle();
    expect(find.text('Add magnet link'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'ffffffffffffffffffffffffffffffffffffffff',
    );
    await tester.tap(find.text('OK'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Magnet FFFFFFFF'), findsOneWidget);
  });

  testWidgets('pause and resume torrent via toggle', (tester) async {
    await tester.pumpWidget(const GetzyApp());
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Ubuntu Desktop 24.04 LTS'), findsOneWidget);

    final pauseButton = find.byTooltip('Pause torrent');
    expect(pauseButton, findsOneWidget);
    await tester.tap(pauseButton);
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Resume torrent'), findsOneWidget);

    await tester.tap(find.byTooltip('Resume torrent'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 500)),
    );

    expect(find.byTooltip('Pause torrent'), findsOneWidget);
  });

  testWidgets('settings subpages show controls', (tester) async {
    await tester.pumpWidget(const GetzyApp());
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Power management'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Power management'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('WiFi only'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    expect(
      find.textContaining('Download/upload only when charging'),
      findsOneWidget,
    );
  });
}
