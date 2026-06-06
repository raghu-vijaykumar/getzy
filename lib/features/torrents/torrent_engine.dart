import 'dart:async';

import 'package:flutter/foundation.dart';

import 'torrent_models.dart';

enum TorrentEngineState { initializing, running, paused, shutdown, crashed }

class TorrentInputException implements Exception {
  TorrentInputException(this.message);

  final String message;
}

abstract class TorrentEngine extends ChangeNotifier {
  List<TorrentTask> get torrents;
  TorrentSortOption get sortOption;
  bool get isShutdown;
  int get activeTorrentCount;
  int get finishedTorrentCount;
  int get downloadSpeedBytes;
  int get uploadSpeedBytes;
  TorrentEngineState get state;
  Stream<TorrentEngineEvent> get events;

  Future<void> initialize();
  String? validateNewTorrentSource(String source);
  Future<void> addTorrent(String source);
  List<TorrentTask> visibleTorrents(
      {required TorrentBucket bucket, required String query});
  Future<void> toggleTorrent(String id);
  Future<void> resumeAll();
  Future<void> pauseAll();
  Future<void> shutdown();
  Future<void> updateSort(TorrentSortOption option);
  Future<void> reorderQueue(List<String> orderedTorrentIds);
  Future<void> deleteTorrent(String id);
}

abstract class TorrentEngineEvent {}

class TorrentEngineStateChanged extends TorrentEngineEvent {
  TorrentEngineStateChanged(this.state);
  final TorrentEngineState state;
}

class TorrentTaskUpdated extends TorrentEngineEvent {
  TorrentTaskUpdated(this.task);
  final TorrentTask task;
}

class TorrentEngineErrorEvent extends TorrentEngineEvent {
  TorrentEngineErrorEvent(this.error);
  final String error;
}
