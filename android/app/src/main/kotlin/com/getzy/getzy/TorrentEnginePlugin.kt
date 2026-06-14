package com.getzy.getzy

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.Timer
import java.util.TimerTask

class TorrentEnginePlugin(private val context: Context) {
    private val channelName = "getzy/torrent_engine"
    private val eventChannelName = "getzy/torrent_engine_status"
    private var wakeLock: PowerManager.WakeLock? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var statusTimer: Timer? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var sessionPtr: Long = 0

    fun register(flutterEngine: FlutterEngine) {
        TorrentBridge.load()

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )
        methodChannel?.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }

        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName
        )
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                eventSink = sink
                startStatusPolling()
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                stopStatusPolling()
            }
        })
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                if (TorrentBridge.isLoaded) {
                    sessionPtr = TorrentBridge.createSession(context)
                    result.success(sessionPtr != 0L)
                } else {
                    result.success(false)
                }
            }
            "shutdown" -> {
                TorrentBridge.destroySession()
                sessionPtr = 0
                stopStatusPolling()
                wakeLock?.let {
                    if (it.isHeld) it.release()
                }
                wakeLock = null
                result.success(null)
            }
            "addTorrent" -> {
                val source = call.argument<String>("source") ?: ""
                if (source.isBlank()) {
                    result.error("INVALID_ARGUMENT", "Source is empty", null)
                    return
                }
                val infoHash = TorrentBridge.addTorrent(source)
                if (infoHash.isEmpty()) {
                    result.error("ADD_FAILED", "Failed to add torrent", null)
                } else {
                    result.success(infoHash)
                }
            }
            "toggleTorrent" -> {
                val id = call.argument<String>("id") ?: ""
                if (id.isBlank()) {
                    result.error("INVALID_ARGUMENT", "Torrent id is empty", null)
                    return
                }
                val statuses = getParsedStatuses()
                var foundStatus: String? = null
                for (i in 0 until statuses.length()) {
                    val obj = statuses.optJSONObject(i)
                    if (obj?.optString("info_hash") == id) {
                        foundStatus = obj.optString("status")
                        break
                    }
                }
                if (foundStatus != null) {
                    if (foundStatus == "paused" || foundStatus == "queued") {
                        TorrentBridge.resumeTorrent(id)
                    } else if (foundStatus == "downloading" || foundStatus == "checking") {
                        TorrentBridge.pauseTorrent(id)
                    }
                }
                result.success(null)
            }
            "resumeAll" -> {
                TorrentBridge.resumeAll()
                result.success(null)
            }
            "pauseAll" -> {
                TorrentBridge.pauseAll()
                result.success(null)
            }
            "deleteTorrent" -> {
                val id = call.argument<String>("id") ?: ""
                TorrentBridge.removeTorrent(id)
                result.success(null)
            }
            "reorderQueue" -> result.success(null)
            "setFilePriorities" -> {
                val infoHash = call.argument<String>("info_hash") ?: ""
                val selected = call.argument<List<String>>("selected_files") ?: emptyList()
                if (infoHash.isNotBlank()) {
                    TorrentBridge.setFilePriorities(infoHash, selected.toTypedArray())
                }
                result.success(null)
            }
            "applySettings" -> {
                val settings = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                val json = JSONObject(settings).toString()
                TorrentBridge.applySettings(json)
                result.success(null)
            }
            "startService" -> {
                val intent = Intent(context, TorrentForegroundService::class.java)
                ContextCompat.startForegroundService(context, intent)
                result.success(null)
            }
            "stopService" -> {
                val intent = Intent(context, TorrentForegroundService::class.java)
                context.stopService(intent)
                result.success(null)
            }
            "updateNotification" -> {
                val args = call.arguments as? Map<String, Any>
                val intent = Intent(context, TorrentForegroundService::class.java).apply {
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
                ContextCompat.startForegroundService(context, intent)
                result.success(null)
            }
            "notificationAction" -> {
                val action = call.arguments as? String
                result.success(null)
            }
            "isAvailable" -> result.success(TorrentBridge.isLoaded)
            "acquireWakeLock" -> {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                if (wakeLock == null) {
                    wakeLock = pm.newWakeLock(
                        PowerManager.PARTIAL_WAKE_LOCK,
                        "Getzy:TorrentWakeLock"
                    )
                }
                wakeLock?.acquire()
                result.success(null)
            }
            "releaseWakeLock" -> {
                wakeLock?.let {
                    if (it.isHeld) it.release()
                }
                wakeLock = null
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun startStatusPolling() {
        stopStatusPolling()
        statusTimer = Timer("TorrentStatusPolling", true).apply {
            schedule(object : TimerTask() {
                override fun run() {
                    val statuses = getParsedStatuses()
                    if (statuses.length() > 0) {
                        mainHandler.post {
                            eventSink?.success(statuses.toString())
                        }
                    }
                }
            }, 0, 1000)
        }
    }

    private fun stopStatusPolling() {
        statusTimer?.cancel()
        statusTimer = null
    }

    private fun getParsedStatuses(): JSONArray {
        val raw = TorrentBridge.getTorrentStatuses()
        val arr = JSONArray()
        for (json in raw) {
            try {
                arr.put(JSONObject(json))
            } catch (_: Exception) {}
        }
        return arr
    }
}
