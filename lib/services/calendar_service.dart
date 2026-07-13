import 'package:flutter/services.dart';
import '../models/task.dart';

class CalendarService {
  static const MethodChannel _channel = MethodChannel('kunst_launcher/platform');

  Future<List<Map<String, Object?>>> listWritableCalendars() async {
    final calendars = await _channel.invokeMethod<List<dynamic>>('listWritableCalendars');
    return calendars
            ?.whereType<Map>()
            .map((calendar) => calendar.map((key, value) => MapEntry(key.toString(), value)))
            .toList() ??
        <Map<String, Object?>>[];
  }

  Future<int> syncTask(Task task, {int? calendarId}) async {
    final startTime = _parseDateTime(task.date, task.startTime ?? '08:00');
    final endTime = _parseDateTime(task.date, task.endTime ?? '09:00');
    final eventId = await _channel.invokeMethod<int>('insertCalendarEvent', {
      'calendarId': calendarId,
      'title': task.name,
      'description': '${task.description}\nWorld: ${task.world}\nType: ${task.type}',
      'dtStart': startTime.millisecondsSinceEpoch,
      'dtEnd': endTime.millisecondsSinceEpoch,
      'timeZone': DateTime.now().timeZoneName,
      'syncData1': task.id?.toString(),
    });
    return eventId ?? -1;
  }

  DateTime _parseDateTime(String date, String time) {
    final parts = time.split(':');
    final hours = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(
      int.parse(date.substring(0, 4)),
      int.parse(date.substring(5, 7)),
      int.parse(date.substring(8, 10)),
      hours,
      minutes,
    );
  }
}