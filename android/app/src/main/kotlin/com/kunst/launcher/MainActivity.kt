package com.kunst.launcher

import android.Manifest
import android.app.admin.DevicePolicyManager
import android.app.AppOpsManager
import android.app.AlarmManager
import android.content.ComponentName
import android.content.Intent
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.os.PowerManager
import android.provider.Settings
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.PendingIntent

class MainActivity: FlutterFragmentActivity() {
	private var pendingCalendarPermissionResult: MethodChannel.Result? = null
	private var pendingCalendarEventResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kunst_launcher/platform")
		methodChannel.setMethodCallHandler { call, result ->
			when (call.method) {
				"isDeviceAdminActive" -> {
					val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
					val admin = ComponentName(this@MainActivity, AdminReceiver::class.java)
					result.success(dpm.isAdminActive(admin))
				}
				"isNotificationListenerEnabled" -> {
					val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: ""
					result.success(enabled.contains(packageName))
				}
				"isUsageAccessGranted" -> {
					val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
					val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
					result.success(mode == AppOpsManager.MODE_ALLOWED)
				}
				"hasCalendarPermissions" -> {
					val read = ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED
					val write = ActivityCompat.checkSelfPermission(this, Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED
					result.success(read && write)
				}
				"canScheduleExactAlarms" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
						val am = getSystemService(AlarmManager::class.java)
						result.success(am?.canScheduleExactAlarms() ?: true)
					} else {
						result.success(true)
					}
				}
				"isIgnoringBatteryOptimizations" -> {
					val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
					result.success(pm.isIgnoringBatteryOptimizations(packageName))
				}
				"hideApp" -> {
					val pkg = call.argument<String>("package") ?: ""
					val ok = AppManager(this@MainActivity).setAppHidden(pkg, true)
					result.success(ok)
				}
				"showApp" -> {
					val pkg = call.argument<String>("package") ?: ""
					val ok = AppManager(this@MainActivity).setAppHidden(pkg, false)
					result.success(ok)
				}
				"isAppHidden" -> {
					val pkg = call.argument<String>("package") ?: ""
					val hidden = AppManager(this@MainActivity).isAppHidden(pkg)
					result.success(hidden)
				}
				"killApp" -> {
					val pkg = call.argument<String>("package") ?: ""
					val ok = AppManager(this@MainActivity).killApp(pkg)
					result.success(ok)
				}
				"bulkHideApps" -> {
					val packages = call.argument<List<*>>("packages")?.mapNotNull { it as? String } ?: emptyList()
					var ok = true
					for (p in packages) {
						if (!AppManager(this@MainActivity).setAppHidden(p, true)) ok = false
					}
					result.success(ok)
				}
				"bulkShowApps" -> {
					val packages = call.argument<List<*>>("packages")?.mapNotNull { it as? String } ?: emptyList()
					var ok = true
					for (p in packages) {
						if (!AppManager(this@MainActivity).setAppHidden(p, false)) ok = false
					}
					result.success(ok)
				}
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
				"drainBlockedQueuePrefs" -> {
					val prefs = getSharedPreferences("kunst_notifications", MODE_PRIVATE)
					val existing = prefs.getString("blocked_queue", "[]") ?: "[]"
					// clear after reading
					prefs.edit().putString("blocked_queue", "[]").apply()
					try {
						val arr = org.json.JSONArray(existing)
						val out = ArrayList<Map<String, Any?>>()
						for (i in 0 until arr.length()) {
							val obj = arr.getJSONObject(i)
							out.add(mapOf(
								"packageName" to obj.optString("packageName"),
								"title" to obj.optString("title"),
								"text" to obj.optString("text"),
								"timestamp" to obj.optLong("timestamp")
							))
						}
						result.success(out)
					} catch (e: Exception) {
						result.success(emptyList<Map<String, Any?>>())
					}
				}
				"scheduleExactAlarm" -> {
					val args = call.arguments as? Map<*, *>
					if (args == null) {
						result.error("bad_args", "Missing args", null)
					} else {
						val id = (args["id"] as? Number)?.toInt() ?: 0
						val ts = (args["timestamp"] as? Number)?.toLong() ?: 0L
						val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
						val intent = Intent(this@MainActivity, AlarmReceiver::class.java).apply {
							putExtra("alarm_id", id)
						}
						val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
						val pi = PendingIntent.getBroadcast(this@MainActivity, id, intent, flags)
						try {
							if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
								am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, ts, pi)
							} else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
								am.setExact(AlarmManager.RTC_WAKEUP, ts, pi)
							} else {
								am.set(AlarmManager.RTC_WAKEUP, ts, pi)
							}
							// persist scheduled alarm in prefs for boot re-registration
							try {
								val prefs = getSharedPreferences("kunst_alarms", MODE_PRIVATE)
								val existing = prefs.getString("scheduled_alarms", "[]") ?: "[]"
								val arr = org.json.JSONArray(existing)
								val obj = org.json.JSONObject()
								obj.put("id", id)
								obj.put("timestamp", ts)
								arr.put(obj)
								prefs.edit().putString("scheduled_alarms", arr.toString()).apply()
							} catch (_: Exception) {}
							result.success(true)
						} catch (e: Exception) {
							result.error("alarm_error", e.message, null)
						}
					}
				}
				"cancelExactAlarm" -> {
					val args = call.arguments as? Map<*, *>
					if (args == null) {
						result.error("bad_args", "Missing args", null)
					} else {
						val id = (args["id"] as? Number)?.toInt() ?: 0
						val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
						val intent = Intent(this@MainActivity, AlarmReceiver::class.java)
						val flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
						val pi = PendingIntent.getBroadcast(this@MainActivity, id, intent, flags)
						if (pi != null) {
							am.cancel(pi)
							pi.cancel()
							// remove from persisted scheduled_alarms
							try {
								val prefs = getSharedPreferences("kunst_alarms", MODE_PRIVATE)
								val existing = prefs.getString("scheduled_alarms", "[]") ?: "[]"
								val arr = org.json.JSONArray(existing)
								val out = org.json.JSONArray()
								for (i in 0 until arr.length()) {
									val o = arr.getJSONObject(i)
									if (o.optInt("id") != id) out.put(o)
								}
								prefs.edit().putString("scheduled_alarms", out.toString()).apply()
							} catch (_: Exception) {}
							result.success(true)
						} else {
							result.success(false)
						}
					}
				}
				else -> result.notImplemented()
			}
		}

		// Register broadcast receiver for blocked notifications so the foreground app can persist them immediately
		val receiver = object : android.content.BroadcastReceiver() {
			override fun onReceive(context: Context?, intent: android.content.Intent?) {
				if (intent == null) return
				if (intent.action == "com.kunst.launcher.NOTIFICATION_BLOCKED") {
					val pkg = intent.getStringExtra("packageName") ?: ""
					val title = intent.getStringExtra("title") ?: ""
					val text = intent.getStringExtra("text") ?: ""
					val ts = intent.getLongExtra("timestamp", 0L)
					try {
						methodChannel.invokeMethod("notificationBlocked", mapOf(
							"packageName" to pkg,
							"title" to title,
							"text" to text,
							"timestamp" to ts,
						))
					} catch (_: Exception) {
					}
				}
			}
		}
		registerReceiver(receiver, android.content.IntentFilter("com.kunst.launcher.NOTIFICATION_BLOCKED"))

		// listen for alarm fired broadcasts and forward to Flutter
		val alarmReceiver = object : android.content.BroadcastReceiver() {
			override fun onReceive(context: Context?, intent: android.content.Intent?) {
				if (intent == null) return
				if (intent.action == "com.kunst.launcher.ALARM_FIRED") {
					val alarmId = intent.getIntExtra("alarm_id", -1)
					try {
						methodChannel.invokeMethod("alarmFired", mapOf("id" to alarmId))
					} catch (_: Exception) {
					}
				}
			}
		}
		registerReceiver(alarmReceiver, android.content.IntentFilter("com.kunst.launcher.ALARM_FIRED"))
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
			CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
			CalendarContract.Calendars.SYNC_EVENTS,
		)
		val selection = "${CalendarContract.Calendars.VISIBLE} = 1"
		contentResolver.query(CalendarContract.Calendars.CONTENT_URI, projection, selection, null, null)?.use { cursor ->
			val idIndex = cursor.getColumnIndex(CalendarContract.Calendars._ID)
			val nameIndex = cursor.getColumnIndex(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)
			val ownerIndex = cursor.getColumnIndex(CalendarContract.Calendars.OWNER_ACCOUNT)
			while (cursor.moveToNext()) {
				val accessLevel = cursor.getInt(cursor.getColumnIndex(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL))
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
