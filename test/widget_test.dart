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

  testWidgets('renders Getzy home with torrent tabs and mock data',
      (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    expect(find.text('Getzy'), findsOneWidget);
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('QUEUED'), findsOneWidget);
    expect(find.text('FINISHED'), findsOneWidget);
    expect(find.text('Ubuntu Desktop 24.04 LTS'), findsOneWidget);
    expect(find.text('Add torrent'), findsOneWidget);
  });

  testWidgets('filters torrents from the search toolbar', (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('Search torrents'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fedora');
    await tester.pumpAndSettle();

    expect(find.text('Fedora Workstation Live x86_64'), findsOneWidget);
    expect(find.text('Ubuntu Desktop 24.04 LTS'), findsNothing);
  });

  testWidgets('adds a valid info hash through the add torrent dialog',
      (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.text('Add torrent'));
    await tester.pumpAndSettle();
    expect(find.text('Add magnet link'), findsOneWidget);

    await tester.enterText(
        find.byType(TextField), 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Magnet AAAAAAAA'), findsOneWidget);
  });

  testWidgets('opens settings from the overflow menu', (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Bandwidth'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Privacy & Security'), findsOneWidget);
  });

  testWidgets('opens modify queue from the overflow menu', (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modify queue'));
    await tester.pumpAndSettle();

    expect(find.text('Modify queue'), findsOneWidget);
    expect(find.byType(ReorderableListView), findsOneWidget);
  });

  testWidgets('manages RSS feeds with add and refresh actions', (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feeds'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Feed manager'), findsOneWidget);
    await tester.tap(find.byTooltip('Add feed'));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Public torrents');
    await tester.enterText(
        find.byType(TextField).last, 'https://example.com/public-torrents.xml');
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Public torrents'), findsOneWidget);
    expect(
        find.text('https://example.com/public-torrents.xml'), findsOneWidget);
  });

  testWidgets('accepts local .torrent file paths in the add torrent dialog',
      (tester) async {
    await tester.pumpWidget(GetzyApp(engine: engine));
    await tester.pump();

    await tester.tap(find.text('Add torrent'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField), '/storage/emulated/0/Download/sample.torrent');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('sample'), findsOneWidget);
  });
}
