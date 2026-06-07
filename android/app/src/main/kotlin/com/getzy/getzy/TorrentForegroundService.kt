package com.getzy.getzy

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class TorrentForegroundService : Service() {
    companion object {
        private const val channelId = "getzy_foreground_channel"
        private const val notificationId = 1453

        const val EXTRA_TORRENT_COUNT = "torrent_count"
        const val EXTRA_ACTIVE_COUNT = "active_count"
        const val EXTRA_DOWNLOAD_SPEED = "download_speed"
        const val EXTRA_UPLOAD_SPEED = "upload_speed"
        const val EXTRA_TITLE = "notification_title"
        const val EXTRA_TEXT = "notification_text"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val torrentCount = intent?.getIntExtra(EXTRA_TORRENT_COUNT, 0) ?: 0
        val activeCount = intent?.getIntExtra(EXTRA_ACTIVE_COUNT, 0) ?: 0
        val downloadSpeed = intent?.getStringExtra(EXTRA_DOWNLOAD_SPEED) ?: ""
        val uploadSpeed = intent?.getStringExtra(EXTRA_UPLOAD_SPEED) ?: ""
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Getzy torrent engine"
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: "Background download session is active"

        val notification = createNotification(title, text, torrentCount, activeCount, downloadSpeed, uploadSpeed)
        startForeground(notificationId, notification)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        stopForeground(true)
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Getzy foreground service",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Torrent engine foreground service channel"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(
        title: String,
        text: String,
        torrentCount: Int,
        activeCount: Int,
        downloadSpeed: String,
        uploadSpeed: String,
    ): Notification {
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val pauseIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "com.getzy.action.PAUSE_ALL"
        }
        val pausePendingIntent = PendingIntent.getBroadcast(
            this, 1, pauseIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val resumeIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "com.getzy.action.RESUME_ALL"
        }
        val resumePendingIntent = PendingIntent.getBroadcast(
            this, 2, resumeIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val shutdownIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "com.getzy.action.SHUTDOWN"
        }
        val shutdownPendingIntent = PendingIntent.getBroadcast(
            this, 3, shutdownIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val speedInfo = if (downloadSpeed.isNotEmpty() || uploadSpeed.isNotEmpty()) {
            "DL: $downloadSpeed | UL: $uploadSpeed"
        } else {
            null
        }

        val builder = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(openAppPendingIntent)

        if (torrentCount > 0) {
            builder.setSubText("$activeCount active / $torrentCount total")
        }

        if (speedInfo != null) {
            builder.setStyle(NotificationCompat.BigTextStyle().bigText("$text\n$speedInfo"))
        }

        builder
            .addAction(0, "Pause", pausePendingIntent)
            .addAction(0, "Resume", resumePendingIntent)
            .addAction(0, "Shutdown", shutdownPendingIntent)

        return builder.build()
    }
}
