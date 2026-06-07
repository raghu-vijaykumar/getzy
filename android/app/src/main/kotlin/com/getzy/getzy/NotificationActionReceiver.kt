package com.getzy.getzy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val serviceIntent = Intent(context, TorrentForegroundService::class.java)

        when (action) {
            "com.getzy.action.PAUSE_ALL" -> {
                // Forward to Flutter via a method channel call
                val pauseIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("notification_action", "pause_all")
                }
                context.startActivity(pauseIntent)
            }
            "com.getzy.action.RESUME_ALL" -> {
                val resumeIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("notification_action", "resume_all")
                }
                context.startActivity(resumeIntent)
            }
            "com.getzy.action.SHUTDOWN" -> {
                context.stopService(serviceIntent)
                val shutdownIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("notification_action", "shutdown")
                }
                context.startActivity(shutdownIntent)
            }
        }
    }
}
