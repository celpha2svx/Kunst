import 'package:flutter/services.dart';

class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('kunst_launcher/platform');

  Future<bool> requestDeviceAdmin() async {
    return (await _channel.invokeMethod<bool>('requestDeviceAdmin')) ?? false;
  }

  Future<bool> openNotificationListenerSettings() async {
    return (await _channel.invokeMethod<bool>('openNotificationListenerSettings')) ?? false;
  }

  Future<bool> openUsageAccessSettings() async {
    return (await _channel.invokeMethod<bool>('openUsageAccessSettings')) ?? false;
  }

  Future<bool> requestCalendarPermissions() async {
    return (await _channel.invokeMethod<bool>('requestCalendarPermissions')) ?? false;
  }

  Future<bool> requestExactAlarmSettings() async {
    return (await _channel.invokeMethod<bool>('requestExactAlarmSettings')) ?? false;
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    return (await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations')) ?? false;
  }

  Future<bool> isDeviceAdminActive() async {
    return (await _channel.invokeMethod<bool>('isDeviceAdminActive')) ?? false;
  }

  Future<bool> isNotificationListenerEnabled() async {
    return (await _channel.invokeMethod<bool>('isNotificationListenerEnabled')) ?? false;
  }

  Future<bool> isUsageAccessGranted() async {
    return (await _channel.invokeMethod<bool>('isUsageAccessGranted')) ?? false;
  }

  Future<bool> hasCalendarPermissions() async {
    return (await _channel.invokeMethod<bool>('hasCalendarPermissions')) ?? false;
  }

  Future<bool> canScheduleExactAlarms() async {
    return (await _channel.invokeMethod<bool>('canScheduleExactAlarms')) ?? true;
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    return (await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations')) ?? false;
  }

  Future<List<Map<String, dynamic>>> drainBlockedQueuePrefs() async {
    final res = await _channel.invokeMethod<dynamic>('drainBlockedQueuePrefs');
    if (res is List) {
      return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}