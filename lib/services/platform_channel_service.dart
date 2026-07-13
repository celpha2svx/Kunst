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
}