import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationQueueService {
  static const String _prefsKey = 'blocked_queue';

  Future<List<Map<String, Object?>>> loadQueuedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey) ?? '[]';
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((entry) => entry.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  Future<void> clearQueuedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, '[]');
  }
}