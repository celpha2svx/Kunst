import 'package:flutter/services.dart';

class AlarmManagerService {
  static const MethodChannel _channel = MethodChannel('kunst_launcher/platform');

  Future<bool> scheduleExactAlarm(int id, DateTime when) async {
    final args = {'id': id, 'timestamp': when.millisecondsSinceEpoch};
    return (await _channel.invokeMethod<bool>('scheduleExactAlarm', args)) ?? false;
  }

  Future<bool> cancelAlarm(int id) async {
    return (await _channel.invokeMethod<bool>('cancelExactAlarm', {'id': id})) ?? false;
  }
}
