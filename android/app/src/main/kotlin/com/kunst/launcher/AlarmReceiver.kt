package com.kunst.launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val alarmId = intent.getIntExtra("alarm_id", -1)
            val b = Intent("com.kunst.launcher.ALARM_FIRED")
            b.putExtra("alarm_id", alarmId)
            context.sendBroadcast(b)
        } catch (_: Exception) {
        }
    }
}
