package com.getzy.getzy

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "getzy/torrent_engine"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(true)
                "startService" -> {
                    val intent = Intent(this, TorrentForegroundService::class.java)
                    ContextCompat.startForegroundService(this, intent)
                    result.success(null)
                }
                "stopService" -> {
                    val intent = Intent(this, TorrentForegroundService::class.java)
                    stopService(intent)
                    result.success(null)
                }
                "addTorrent", "toggleTorrent", "reorderQueue" -> {
                    // Native service stub for future libtorrent integration.
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

