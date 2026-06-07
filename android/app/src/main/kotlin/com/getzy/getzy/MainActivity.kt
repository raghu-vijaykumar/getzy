package com.getzy.getzy

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val channelName = "getzy/torrent_engine"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(true)
                    "startService" -> {
                        val intent = Intent(this@MainActivity, TorrentForegroundService::class.java)
                        ContextCompat.startForegroundService(this@MainActivity, intent)
                        result.success(null)
                    }
                    "stopService" -> {
                        val intent = Intent(this@MainActivity, TorrentForegroundService::class.java)
                        stopService(intent)
                        result.success(null)
                    }
                    "updateNotification" -> {
                        val args = call.arguments as? Map<String, Any>
                        val intent = Intent(this@MainActivity, TorrentForegroundService::class.java).apply {
                            putExtra(TorrentForegroundService.EXTRA_TORRENT_COUNT,
                                (args?.get("torrent_count") as? Int) ?: 0)
                            putExtra(TorrentForegroundService.EXTRA_ACTIVE_COUNT,
                                (args?.get("active_count") as? Int) ?: 0)
                            putExtra(TorrentForegroundService.EXTRA_DOWNLOAD_SPEED,
                                (args?.get("download_speed") as? String) ?: "")
                            putExtra(TorrentForegroundService.EXTRA_UPLOAD_SPEED,
                                (args?.get("upload_speed") as? String) ?: "")
                            putExtra(TorrentForegroundService.EXTRA_TITLE,
                                (args?.get("notification_title") as? String) ?: "Getzy torrent engine")
                            putExtra(TorrentForegroundService.EXTRA_TEXT,
                                (args?.get("notification_text") as? String) ?: "Background download session is active")
                        }
                        ContextCompat.startForegroundService(this@MainActivity, intent)
                        result.success(null)
                    }
                    "addTorrent", "toggleTorrent", "reorderQueue" -> {
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationAction(intent)
        setIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        handleNotificationAction(intent)
    }

    private fun handleNotificationAction(intent: Intent?) {
        val action = intent?.getStringExtra("notification_action") ?: return
        methodChannel?.invokeMethod("notificationAction", action)
    }
}
