import 'dart:math';

enum TorrentBucket { all, queued, finished }

enum TorrentStatus { queued, downloading, paused, checking, finished, blocked }

enum TorrentSortOption {
  queueNumber,
  name,
  dateAdded,
  dateFinished,
  downloadSpeed,
  uploadSpeed,
  eta,
}

extension TorrentStatusLabels on TorrentStatus {
  String get label {
    switch (this) {
      case TorrentStatus.queued:
        return 'Queued';
      case TorrentStatus.downloading:
        return 'Downloading';
      case TorrentStatus.paused:
        return 'Paused';
      case TorrentStatus.checking:
        return 'Checking';
      case TorrentStatus.finished:
        return 'Finished';
      case TorrentStatus.blocked:
        return 'Blocked';
    }
  }

  bool get canToggle =>
      this != TorrentStatus.finished && this != TorrentStatus.blocked;

  bool get isRunning =>
      this == TorrentStatus.downloading || this == TorrentStatus.checking;
}

extension TorrentSortOptionLabels on TorrentSortOption {
  String get label {
    switch (this) {
      case TorrentSortOption.queueNumber:
        return 'Queue number';
      case TorrentSortOption.name:
        return 'Name';
      case TorrentSortOption.dateAdded:
        return 'Date added';
      case TorrentSortOption.dateFinished:
        return 'Date finished';
      case TorrentSortOption.downloadSpeed:
        return 'Download speed';
      case TorrentSortOption.uploadSpeed:
        return 'Upload speed';
      case TorrentSortOption.eta:
        return 'ETA';
    }
  }
}

class TorrentTask {
  const TorrentTask({
    required this.id,
    required this.name,
    required this.infoHash,
    required this.queueNumber,
    required this.status,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.downloadSpeedBytes,
    required this.uploadSpeedBytes,
    required this.dateAdded,
    this.dateFinished,
    this.eta,
    this.blockedReason,
  });

  final String id;
  final String name;
  final String infoHash;
  final int queueNumber;
  final TorrentStatus status;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final int downloadSpeedBytes;
  final int uploadSpeedBytes;
  final DateTime dateAdded;
  final DateTime? dateFinished;
  final Duration? eta;
  final String? blockedReason;

  TorrentTask copyWith({
    String? id,
    String? name,
    String? infoHash,
    int? queueNumber,
    TorrentStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    int? downloadSpeedBytes,
    int? uploadSpeedBytes,
    DateTime? dateAdded,
    DateTime? dateFinished,
    Duration? eta,
    String? blockedReason,
  }) {
    return TorrentTask(
      id: id ?? this.id,
      name: name ?? this.name,
      infoHash: infoHash ?? this.infoHash,
      queueNumber: queueNumber ?? this.queueNumber,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadSpeedBytes: downloadSpeedBytes ?? this.downloadSpeedBytes,
      uploadSpeedBytes: uploadSpeedBytes ?? this.uploadSpeedBytes,
      dateAdded: dateAdded ?? this.dateAdded,
      dateFinished: dateFinished ?? this.dateFinished,
      eta: eta ?? this.eta,
      blockedReason: blockedReason ?? this.blockedReason,
    );
  }

  factory TorrentTask.fromMap(Map<String, Object?> map) {
    return TorrentTask(
      id: map['id'] as String,
      name: map['name'] as String,
      infoHash: map['info_hash'] as String,
      queueNumber: map['queue_number'] as int,
      status: TorrentStatusExtension.fromString(map['status'] as String),
      progress: map['progress'] as double,
      downloadedBytes: map['downloaded_bytes'] as int,
      totalBytes: map['total_bytes'] as int,
      downloadSpeedBytes: map['download_speed_bytes'] as int,
      uploadSpeedBytes: map['upload_speed_bytes'] as int,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int),
      dateFinished: map['date_finished'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['date_finished'] as int),
      eta: map['eta_seconds'] == null
          ? null
          : Duration(seconds: map['eta_seconds'] as int),
      blockedReason: map['blocked_reason'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'info_hash': infoHash,
      'queue_number': queueNumber,
      'status': status.name,
      'progress': progress,
      'downloaded_bytes': downloadedBytes,
      'total_bytes': totalBytes,
      'download_speed_bytes': downloadSpeedBytes,
      'upload_speed_bytes': uploadSpeedBytes,
      'date_added': dateAdded.millisecondsSinceEpoch,
      'date_finished': dateFinished?.millisecondsSinceEpoch,
      'eta_seconds': eta?.inSeconds,
      'blocked_reason': blockedReason,
    };
  }
}

extension TorrentStatusExtension on TorrentStatus {
  static TorrentStatus fromString(String value) {
    return TorrentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TorrentStatus.queued,
    );
  }
}

class TorrentFile {
  TorrentFile({
    required this.path,
    required this.lengthBytes,
    required this.priority,
    required this.progress,
    required this.selected,
  });

  final String path;
  final int lengthBytes;
  final TorrentFilePriority priority;
  final double progress;
  final bool selected;
}

enum TorrentFilePriority { high, normal, low }

class EngineSession {
  const EngineSession({
    required this.uploadedBytes,
    required this.downloadedBytes,
    required this.activeConnections,
    required this.lastUpdated,
  });

  final int uploadedBytes;
  final int downloadedBytes;
  final int activeConnections;
  final DateTime lastUpdated;
}

String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  if (bytes == 0) {
    return '0.0 KB';
  }

  final exponent = min((log(bytes) / log(1024)).floor(), units.length - 1);
  final value = bytes / pow(1024, exponent);
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[exponent]}';
}

String formatSpeed(int bytesPerSecond) {
  return '${formatBytes(bytesPerSecond)}/s';
}

String formatEta(Duration? eta) {
  if (eta == null) {
    return '--';
  }

  final hours = eta.inHours;
  final minutes = eta.inMinutes.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${max(minutes, 1)}m';
}
