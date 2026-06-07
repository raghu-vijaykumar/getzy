import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getzy/features/onboarding/onboarding_screen.dart';
import 'package:getzy/features/torrents/torrent_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '${Directory.systemTemp.path}/getzy_test';
      },
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    TorrentDatabase.instance.reset();
  });

  testWidgets('shows title, legal notice and privacy policy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          homeBuilder: (_) => const Scaffold(body: Text('Home Screen')),
        ),
      ),
    );

    expect(find.text('Getzy'), findsOneWidget);
    expect(find.text('Torrent Downloader'), findsOneWidget);
    expect(find.text('Legal notice'), findsOneWidget);
    expect(find.text('Continue'), findsWidgets);
    expect(find.textContaining('I understand'), findsOneWidget);
    expect(
      find.textContaining('Getzy is a torrent downloader'),
      findsOneWidget,
    );

    await tester.dragUntilVisible(
      find.text('Privacy policy'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pump();
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(
      find.textContaining('Getzy does not collect'),
      findsOneWidget,
    );
  });

  testWidgets('Continue button is disabled before accepting', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          homeBuilder: (_) => const Scaffold(body: Text('Home Screen')),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Continue button is enabled after checking checkbox',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          homeBuilder: (_) => const Scaffold(body: Text('Home Screen')),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('tapping the label text also toggles the checkbox',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          homeBuilder: (_) => const Scaffold(body: Text('Home Screen')),
        ),
      ),
    );

    await tester.tap(find.textContaining('I understand'));
    await tester.pump();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  testWidgets('accepting navigates to home screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          homeBuilder: (_) => const Scaffold(body: Text('Home Screen')),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
  });
}
