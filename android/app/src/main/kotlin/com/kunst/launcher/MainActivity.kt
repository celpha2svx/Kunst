package com.kunst.launcher

import android.Manifest
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Intent
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
	private var pendingCalendarPermissionResult: MethodChannel.Result? = null
	private var pendingCalendarEventResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kunst_launcher/platform").setMethodCallHandler { call, result ->
			when (call.method) {
				"requestDeviceAdmin" -> {
					startActivity(
						Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
							putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, ComponentName(this@MainActivity, AdminReceiver::class.java))
							putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "KUNST Launcher needs device admin to hide distracting apps and enforce focus mode.")
						}
					)
					result.success(true)
				}
				"openNotificationListenerSettings" -> {
					startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
					result.success(true)
				}
				"openUsageAccessSettings" -> {
					startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
					result.success(true)
				}
				"requestCalendarPermissions" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
						pendingCalendarPermissionResult = result
						ActivityCompat.requestPermissions(
							this,
							arrayOf(
								Manifest.permission.READ_CALENDAR,
								Manifest.permission.WRITE_CALENDAR,
							),
							1001,
						)
					} else {
						result.success(true)
					}
				}
				"requestExactAlarmSettings" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
						startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
							data = Uri.parse("package:$packageName")
						})
					}
					result.success(true)
				}
				"requestIgnoreBatteryOptimizations" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
						startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
							data = Uri.parse("package:$packageName")
						})
					}
					result.success(true)
				}
				"listWritableCalendars" -> {
					result.success(listWritableCalendars())
				}
				"insertCalendarEvent" -> {
					val arguments = call.arguments as? Map<*, *>
					if (arguments == null) {
						result.error("bad_args", "Missing calendar event arguments", null)
					} else {
						result.success(insertCalendarEvent(arguments))
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode == 1001) {
			val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
			pendingCalendarPermissionResult?.success(granted)
			pendingCalendarPermissionResult = null
		}
	}

	private fun listWritableCalendars(): List<Map<String, Any?>> {
		val calendars = mutableListOf<Map<String, Any?>>()
		val projection = arrayOf(
			CalendarContract.Calendars._ID,
			CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
			CalendarContract.Calendars.OWNER_ACCOUNT,
			CalendarContract.Calendars.VISIBLE,
			CalendarContract.Calendars.CAN_ORGANIZER_RESPOND,
			CalendarContract.Calendars.ALLOWED_ACCESS_LEVEL,
			CalendarContract.Calendars.SYNC_EVENTS,
		)
		val selection = "${CalendarContract.Calendars.VISIBLE} = 1"
		contentResolver.query(CalendarContract.Calendars.CONTENT_URI, projection, selection, null, null)?.use { cursor ->
			val idIndex = cursor.getColumnIndex(CalendarContract.Calendars._ID)
			val nameIndex = cursor.getColumnIndex(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)
			val ownerIndex = cursor.getColumnIndex(CalendarContract.Calendars.OWNER_ACCOUNT)
			while (cursor.moveToNext()) {
				val accessLevel = cursor.getInt(cursor.getColumnIndex(CalendarContract.Calendars.ALLOWED_ACCESS_LEVEL))
				if (accessLevel < CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR) {
					continue
				}
				calendars.add(
					mapOf(
						"id" to cursor.getLong(idIndex),
						"name" to cursor.getString(nameIndex),
						"owner" to cursor.getString(ownerIndex),
					)
				)
			}
		}
		return calendars
	}

	private fun insertCalendarEvent(arguments: Map<*, *>): Long {
		val calendarId = (arguments["calendarId"] as? Number)?.toLong() ?: findDefaultCalendarId()
		if (calendarId == null) {
			return -1L
		}

		val values = ContentValues().apply {
			put(CalendarContract.Events.CALENDAR_ID, calendarId)
			put(CalendarContract.Events.TITLE, arguments["title"]?.toString())
			put(CalendarContract.Events.DESCRIPTION, arguments["description"]?.toString())
			put(CalendarContract.Events.DTSTART, (arguments["dtStart"] as Number).toLong())
			put(CalendarContract.Events.DTEND, (arguments["dtEnd"] as Number).toLong())
			put(CalendarContract.Events.EVENT_TIMEZONE, arguments["timeZone"]?.toString() ?: java.util.TimeZone.getDefault().id)
			put(CalendarContract.Events.SYNC_DATA1, arguments["syncData1"]?.toString())
		}

		val uri = contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
		return uri?.lastPathSegment?.toLongOrNull() ?: -1L
	}

	private fun findDefaultCalendarId(): Long? {
		val projection = arrayOf(CalendarContract.Calendars._ID)
		val selection = "${CalendarContract.Calendars.VISIBLE} = 1"
		contentResolver.query(CalendarContract.Calendars.CONTENT_URI, projection, selection, null, null)?.use { cursor ->
			if (cursor.moveToFirst()) {
				return cursor.getLong(0)
			}
		}
		return null
	}
}
