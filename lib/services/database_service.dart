import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initialize();
    return _db!;
  }

  Future<Database> _initialize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'kunst.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            world TEXT NOT NULL,
            time_state TEXT NOT NULL,
            type TEXT NOT NULL,
            apps_needed TEXT,
            date TEXT NOT NULL,
            start_time TEXT,
            end_time TEXT,
            priority INTEGER DEFAULT 1,
            status TEXT DEFAULT 'pending',
            calendar_event_id TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at TEXT
          )
        ''');

        await db.insert('settings', {
          'key': 'theme',
          'value': 'dark_grey',
          'updated_at': DateTime.now().toIso8601String(),
        });
      },
    );
  }

  Future<List<Map<String, Object?>>> getTasksForDate(String date) async {
    final db = await database;
    return db.query(
      'tasks',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'start_time ASC',
    );
  }

  Future<int> insertTask(Map<String, Object?> task) async {
    final db = await database;
    return db.insert('tasks', {
      ...task,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateTask(int id, Map<String, Object?> updates) async {
    final db = await database;
    return db.update(
      'tasks',
      {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) {
      return defaultValue;
    }
    return rows.first['value']?.toString() ?? defaultValue;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getAllowedAppsForDate(String date) async {
    final tasks = await getTasksForDate(date);
    final allowed = <String>{'com.samsung.android.dialer', 'com.samsung.android.messaging'};
    for (final task in tasks) {
      final appsRaw = task['apps_needed'];
      if (appsRaw is String && appsRaw.isNotEmpty) {
        final decoded = jsonDecode(appsRaw) as List<dynamic>;
        allowed.addAll(decoded.map((e) => e.toString()));
      }
    }
    return allowed.toList();
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('settings');
    await db.insert('settings', {
      'key': 'theme',
      'value': 'dark_grey',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
