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
      version: 2,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedDefaults(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS worlds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            color TEXT,
            icon TEXT,
            sort_order INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
          )
        ''');
          await _seedWorldDefaults(db);
        }
      },
      onOpen: (db) async {
        await _seedDefaults(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
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

    await db.execute('''
          CREATE TABLE worlds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            color TEXT,
            icon TEXT,
            sort_order INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
          )
        ''');
  }

  Future<void> _seedDefaults(Database db) async {
    await db.insert('settings', {
      'key': 'theme',
      'value': 'dark_grey',
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await _seedWorldDefaults(db);
  }

  Future<void> _seedWorldDefaults(Database db) async {
    final defaults = [
      {
        'name': 'Inner',
        'description': 'Personal care, reflection, and internal work.',
        'color': '#121212',
        'icon': 'self_improvement',
        'sort_order': 0,
        'is_active': 1,
      },
      {
        'name': 'Outside',
        'description': 'People, errands, and the external world.',
        'color': '#1e1e1e',
        'icon': 'public',
        'sort_order': 1,
        'is_active': 1,
      },
      {
        'name': 'Future',
        'description': 'Projects, long-term goals, and planning ahead.',
        'color': '#2a2a2a',
        'icon': 'rocket_launch',
        'sort_order': 2,
        'is_active': 1,
      },
    ];

    for (final world in defaults) {
      await db.insert('worlds', {
        ...world,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<Map<String, Object?>>> getWorlds() async {
    final db = await database;
    return db.query('worlds', orderBy: 'sort_order ASC, name ASC');
  }

  Future<int> insertWorld(Map<String, Object?> world) async {
    final db = await database;
    return db.insert('worlds', world, conflictAlgorithm: ConflictAlgorithm.replace);
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
    await db.delete('worlds');
    await _seedDefaults(db);
  }
}
