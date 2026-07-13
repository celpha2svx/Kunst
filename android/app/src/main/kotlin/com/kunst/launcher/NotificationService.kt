package com.kunst.launcher

import android.content.SharedPreferences
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.app.Notification
import android.os.Bundle

class NotificationService : NotificationListenerService() {
    private val socialPackages = setOf(
        "com.whatsapp",
        "com.instagram.android",
        "com.zhiliaoapp.musically",
        "com.twitter.android",
        "com.x.android",
        "org.telegram.messenger",
        "com.facebook.orca",
        "com.facebook.katana",
    )

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!shouldBlock(sbn)) {
            return
        }

        cancelNotification(sbn.key)
        queueBlockedNotification(sbn)
    }

    private fun shouldBlock(sbn: StatusBarNotification): Boolean {
        if (!socialPackages.contains(sbn.packageName)) {
            return false
        }

        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
        val haystack = "$title $text".lowercase()

        val emergencyKeywords = listOf("urgent", "emergency", "hospital", "accident", "help", "asap")
        return emergencyKeywords.none { haystack.contains(it) }
    }

    private fun queueBlockedNotification(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()

        val prefs = getSharedPreferences("kunst_notifications", MODE_PRIVATE)
        val existing = prefs.getString("blocked_queue", "[]") ?: "[]"
        val updated = try {
            val payload = org.json.JSONArray(existing)
            payload.put(
                org.json.JSONObject()
                    .put("packageName", sbn.packageName)
                    .put("title", title)
                    .put("text", text)
                    .put("timestamp", sbn.postTime)
            )
            payload.toString()
        } catch (_: Exception) {
            "[]"
        }

        prefs.edit().putString("blocked_queue", updated).apply()
        // also broadcast so foreground Flutter app can persist immediately
        try {
            val intent = android.content.Intent("com.kunst.launcher.NOTIFICATION_BLOCKED")
            intent.putExtra("packageName", sbn.packageName)
            intent.putExtra("title", title)
            intent.putExtra("text", text)
            intent.putExtra("timestamp", sbn.postTime)
            sendBroadcast(intent)
        } catch (_: Exception) {
        }
    }
}
