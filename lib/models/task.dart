import 'dart:convert';

class Task {
  final int? id;
  final String name;
  final String description;
  final String world;
  final String timeState;
  final String type;
  final List<String> appsNeeded;
  final String date;
  final String? startTime;
  final String? endTime;
  final int priority;
  final String status;
  final String? calendarEventId;
  final String? createdAt;
  final String? updatedAt;

  const Task({
    this.id,
    required this.name,
    required this.description,
    required this.world,
    required this.timeState,
    required this.type,
    required this.appsNeeded,
    required this.date,
    this.startTime,
    this.endTime,
    this.priority = 1,
    this.status = 'pending',
    this.calendarEventId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'world': world,
      'time_state': timeState,
      'type': type,
      'apps_needed': jsonEncode(appsNeeded),
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'priority': priority,
      'status': status,
      'calendar_event_id': calendarEventId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Task copyWith({
    int? id,
    String? name,
    String? description,
    String? world,
    String? timeState,
    String? type,
    List<String>? appsNeeded,
    String? date,
    String? startTime,
    String? endTime,
    int? priority,
    String? status,
    String? calendarEventId,
    String? createdAt,
    String? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      world: world ?? this.world,
      timeState: timeState ?? this.timeState,
      type: type ?? this.type,
      appsNeeded: appsNeeded ?? this.appsNeeded,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      world: map['world']?.toString() ?? 'Inner',
      timeState: map['time_state']?.toString() ?? 'present',
      type: map['type']?.toString() ?? 'immediate',
      appsNeeded: map['apps_needed'] is String && (map['apps_needed'] as String).isNotEmpty
          ? List<String>.from(jsonDecode(map['apps_needed']) as List<dynamic>)
          : const <String>[],
      date: map['date']?.toString() ?? '',
      startTime: map['start_time']?.toString(),
      endTime: map['end_time']?.toString(),
      priority: int.tryParse(map['priority']?.toString() ?? '1') ?? 1,
      status: map['status']?.toString() ?? 'pending',
      calendarEventId: map['calendar_event_id']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }
}
