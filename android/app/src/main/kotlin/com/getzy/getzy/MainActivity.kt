package com.getzy.getzy

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var enginePlugin: TorrentEnginePlugin
    private lateinit var notificationChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        enginePlugin = TorrentEnginePlugin(this)
        enginePlugin.register(flutterEngine)

        notificationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "getzy/torrent_engine"
        )
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
        notificationChannel.invokeMethod("notificationAction", action)
    }
}
