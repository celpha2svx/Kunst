import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class NotificationQueueService {
  static const String _prefsKey = 'blocked_queue';

  Future<List<Map<String, Object?>>> loadQueuedNotifications() async {
    final db = DatabaseService();
    final rows = await db.getBlockedNotifications(limit: 200);
    if (rows.isNotEmpty) return rows;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey) ?? '[]';
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((entry) => entry.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  Future<void> clearQueuedNotifications() async {
    final db = await DatabaseService().database;
    await db.update('notifications_queue', {'processed': 1});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, '[]');
  }
}