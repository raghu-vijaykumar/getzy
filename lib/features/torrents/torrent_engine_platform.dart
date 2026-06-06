import 'package:flutter/services.dart';

class TorrentEnginePlatform {
  static const MethodChannel _channel = MethodChannel('getzy/torrent_engine');

  static Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> startService() async {
    try {
      await _channel.invokeMethod<void>('startService');
    } on MissingPluginException {
      // Native engine is not available on this platform.
    }
  }

  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod<void>('stopService');
    } on MissingPluginException {
      // Native engine is not available on this platform.
    }
  }

  static Future<void> addTorrent(String source) async {
    try {
      await _channel.invokeMethod<void>('addTorrent', {'source': source});
    } on MissingPluginException {
      // Fall back to local implementation.
    }
  }

  static Future<void> toggleTorrent(String id) async {
    try {
      await _channel.invokeMethod<void>('toggleTorrent', {'id': id});
    } on MissingPluginException {
      // Fall back to local implementation.
    }
  }

  static Future<void> reorderQueue(List<String> orderedIds) async {
    try {
      await _channel
          .invokeMethod<void>('reorderQueue', {'orderedIds': orderedIds});
    } on MissingPluginException {
      // Fall back to local implementation.
    }
  }
}
