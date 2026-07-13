package com.kunst.launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            try {
                val prefs = context.getSharedPreferences("kunst_alarms", Context.MODE_PRIVATE)
                val existing = prefs.getString("scheduled_alarms", "[]") ?: "[]"
                val arr = org.json.JSONArray(existing)
                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    val id = o.optInt("id", -1)
                    val ts = o.optLong("timestamp", 0L)
                    if (id < 0 || ts <= 0) continue
                    val intent = Intent(context, AlarmReceiver::class.java).apply {
                        putExtra("alarm_id", id)
                    }
                    val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    val pi = PendingIntent.getBroadcast(context, id, intent, flags)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, ts, pi)
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        am.setExact(AlarmManager.RTC_WAKEUP, ts, pi)
                    } else {
                        am.set(AlarmManager.RTC_WAKEUP, ts, pi)
                    }
                }
            } catch (_: Exception) {}
        }
    }
}
