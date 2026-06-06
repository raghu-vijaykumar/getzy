import 'package:flutter/material.dart';

import '../features/torrents/fake_torrent_engine.dart';
import '../features/torrents/torrent_engine.dart';
import '../features/torrents/torrent_home_screen.dart';
import 'getzy_theme.dart';

class GetzyApp extends StatefulWidget {
  const GetzyApp({super.key});

  @override
  State<GetzyApp> createState() => _GetzyAppState();
}

class _GetzyAppState extends State<GetzyApp> {
  late final TorrentEngine _engine;

  @override
  void initState() {
    super.initState();
    // The fake engine makes the first UI milestone interactive before native libtorrent integration.
    _engine = FakeTorrentEngine.seeded();
    _engine.initialize();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Getzy',
      debugShowCheckedModeBanner: false,
      theme: buildGetzyTheme(),
      home: TorrentHomeScreen(engine: _engine),
    );
  }
}
