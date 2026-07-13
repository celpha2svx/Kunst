package com.kunst.launcher

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context

class AppManager(private val context: Context) {
    fun setAppHidden(packageName: String, hidden: Boolean): Boolean {
        return try {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val admin = ComponentName(context, AdminReceiver::class.java)
            dpm.setApplicationHidden(admin, packageName, hidden)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun isAppHidden(packageName: String): Boolean {
        return try {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val admin = ComponentName(context, AdminReceiver::class.java)
            dpm.isApplicationHidden(admin, packageName)
        } catch (e: Exception) {
            false
        }
    }

    fun killApp(packageName: String): Boolean {
        return try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            am.killBackgroundProcesses(packageName)
            true
        } catch (e: Exception) {
            false
        }
    }
}
