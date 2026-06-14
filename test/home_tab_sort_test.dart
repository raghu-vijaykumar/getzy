import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getzy/app/getzy_app.dart';
import 'package:getzy/features/torrents/fake_torrent_engine.dart';

void main() {
  late FakeTorrentEngine engine;

  setUp(() {
    engine = FakeTorrentEngine.seeded();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '${Directory.systemTemp.path}/getzy_test';
      },
    );
  });

  tearDown(() {
    engine.dispose();
  });

  testWidgets('tapping FINISHED tab shows only finished torrents',
      (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    expect(find.text('LibreOffice Fresh Offline Installers'), findsOneWidget);
    expect(find.text('Ubuntu Desktop 24.04 LTS'), findsOneWidget);

    await tester.tap(find.text('FINISHED'));
    await tester.pumpAndSettle();

    expect(find.text('LibreOffice Fresh Offline Installers'), findsOneWidget);
    expect(find.text('Ubuntu Desktop 24.04 LTS'), findsNothing);
  });

  testWidgets('tapping QUEUED tab excludes finished torrents',
      (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.text('QUEUED'));
    await tester.pumpAndSettle();

    expect(find.text('Ubuntu Desktop 24.04 LTS'), findsOneWidget);
    expect(find.text('Debian 12.5 netinst amd64'), findsOneWidget);
    expect(find.text('Fedora Workstation Live x86_64'), findsOneWidget);
    expect(find.text('LibreOffice Fresh Offline Installers'), findsNothing);
  });

  testWidgets('sort dialog opens and can select a sort option',
      (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('Sort torrents'));
    await tester.pumpAndSettle();

    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Date added'), findsOneWidget);

    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('overflow menu resume all shows snackbar', (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume all'));
    await tester.pumpAndSettle();

    expect(find.text('All eligible torrents resumed'), findsOneWidget);
  });

  testWidgets('overflow menu pause all shows snackbar', (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause all'));
    await tester.pumpAndSettle();

    expect(find.text('All torrents paused'), findsOneWidget);
  });

  testWidgets('overflow menu session status navigates to session screen',
      (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Session status'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Session status'), findsAtLeast(1));
    expect(find.text('TOTAL TRANSFER SPEEDS'), findsOneWidget);
  });

  testWidgets('overflow menu shutdown shows snackbar', (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shutdown'));
    await tester.pumpAndSettle();

    expect(find.text('Engine shutdown simulated'), findsOneWidget);
  });

  testWidgets('torrent row play/pause toggles torrent state',
      (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    expect(find.textContaining('Downloading'), findsAtLeast(1));

    final pauseButtons = find.byTooltip('Pause torrent');
    expect(pauseButtons, findsAtLeast(1));

    await tester.tap(pauseButtons.first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Paused'), findsAtLeast(1));
  });

  testWidgets('tapping torrent row opens detail screen', (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    expect(find.text('Ubuntu Desktop 24.04 LTS'), findsOneWidget);
    await tester.tap(find.text('Ubuntu Desktop 24.04 LTS'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Torrent details'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Trackers'), findsOneWidget);
  });

  testWidgets('search with no results shows empty state', (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('Search torrents'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'XYZZYX');
    await tester.pumpAndSettle();

    expect(find.text('No torrents here'), findsOneWidget);
  });
}
