import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  String _theme = 'dark_grey';
  String _focusStartTime = '06:00';
  String _focusEndTime = '18:00';
  String _sleepStartTime = '22:00';
  String _sleepEndTime = '06:00';
  String _defaultSocialTimer = '30';
  String _maxSocialTimer = '60';
  String _alarmBufferMinutes = '30';
  String _calendarId = '';
  bool _firstLaunchComplete = false;

  String get theme => _theme;
  String get focusStartTime => _focusStartTime;
  String get focusEndTime => _focusEndTime;
  String get sleepStartTime => _sleepStartTime;
  String get sleepEndTime => _sleepEndTime;
  String get defaultSocialTimer => _defaultSocialTimer;
  String get maxSocialTimer => _maxSocialTimer;
  String get alarmBufferMinutes => _alarmBufferMinutes;
  String get calendarId => _calendarId;
  bool get firstLaunchComplete => _firstLaunchComplete;
  bool _loaded = false;
  bool get loaded => _loaded;
  static bool _platformHandlerRegistered = false;

  Future<void> load() async {
    _theme = await _databaseService.getSetting('theme', defaultValue: 'dark_grey');
    _focusStartTime = await _databaseService.getSetting('focus_start_time', defaultValue: '06:00');
    _focusEndTime = await _databaseService.getSetting('focus_end_time', defaultValue: '18:00');
    _sleepStartTime = await _databaseService.getSetting('sleep_start_time', defaultValue: '22:00');
    _sleepEndTime = await _databaseService.getSetting('sleep_end_time', defaultValue: '06:00');
    _defaultSocialTimer = await _databaseService.getSetting('default_social_timer', defaultValue: '30');
    _maxSocialTimer = await _databaseService.getSetting('max_social_timer', defaultValue: '60');
    _alarmBufferMinutes = await _databaseService.getSetting('alarm_buffer_minutes', defaultValue: '30');
    _calendarId = await _databaseService.getSetting('calendar_id', defaultValue: '');
    _firstLaunchComplete = (await _databaseService.getSetting('first_launch_complete', defaultValue: '0')) == '1';
    // migrate any blocked notifications stored in native prefs into the app DB
    await _databaseService.migrateBlockedQueueFromPrefs();
    // register platform handler once to persist blocked notifications when app is foreground
    if (!_platformHandlerRegistered) {
      const MethodChannel('kunst_launcher/platform').setMethodCallHandler((call) async {
        if (call.method == 'notificationBlocked') {
          final args = call.arguments as Map?;
          if (args != null) {
            await _databaseService.insertBlockedNotification({
              'packageName': args['packageName']?.toString(),
              'title': args['title']?.toString(),
              'text': args['text']?.toString(),
              'timestamp': args['timestamp'],
            });
          }
        } else if (call.method == 'alarmFired') {
          final args = call.arguments as Map?;
          final id = args?['id'];
          await _databaseService.insertBlockedNotification({
            'packageName': 'system.alarm',
            'title': 'Alarm fired',
            'text': 'Alarm id: ${id ?? 'unknown'}',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
        return null;
      });
      _platformHandlerRegistered = true;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    _theme = value;
    await _databaseService.setSetting('theme', value);
    notifyListeners();
  }

  Future<void> setCalendarId(String value) async {
    _calendarId = value;
    await _databaseService.setSetting('calendar_id', value);
    notifyListeners();
  }

  Future<void> setFirstLaunchComplete(bool value) async {
    _firstLaunchComplete = value;
    await _databaseService.setSetting('first_launch_complete', value ? '1' : '0');
    notifyListeners();
  }
}
