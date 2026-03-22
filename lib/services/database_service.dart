import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/web_app.dart';

import '../models/app_prompt.dart';

/// Platform-adaptive database service.
/// Uses sqflite for native platforms, in-memory for web.
class DatabaseService {
  static Database? _database;
  static bool _initialized = false;

  // ─── In-memory fallback for web ───
  static final List<WebApp> _memoryStore = [];
  static final Map<String, Map<String, String>> _memoryKvStore = {};
  static final List<AppPrompt> _memoryPrompts = [];

  static Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(dbPath, 'web_render.db'),
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE apps (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            htmlCode TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            iconColor INTEGER NOT NULL DEFAULT 4278218495
          )
        ''');
        await db.execute('''
          CREATE TABLE app_storage (
            appId TEXT NOT NULL,
            key TEXT NOT NULL,
            value TEXT NOT NULL DEFAULT '',
            PRIMARY KEY (appId, key),
            FOREIGN KEY (appId) REFERENCES apps(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE prompts (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_storage (
              appId TEXT NOT NULL,
              key TEXT NOT NULL,
              value TEXT NOT NULL DEFAULT '',
              PRIMARY KEY (appId, key),
              FOREIGN KEY (appId) REFERENCES apps(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS prompts (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return _database!;
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    if (!kIsWeb) {
      await _getDatabase();
    }
    debugPrint(
        'DatabaseService initialized (${kIsWeb ? "web/memory" : "native/sqflite"})');
  }

  // ══════════════════════════════════════════
  //  Apps CRUD
  // ══════════════════════════════════════════

  static Future<List<WebApp>> getAllApps() async {
    await _ensureInitialized();
    if (kIsWeb) {
      return List.from(_memoryStore)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final db = await _getDatabase();
    final maps = await db.query('apps', orderBy: 'updatedAt DESC');
    return maps.map((m) => WebApp.fromMap(m)).toList();
  }

  static Future<WebApp?> getAppById(String id) async {
    await _ensureInitialized();
    if (kIsWeb) {
      try {
        return _memoryStore.firstWhere((a) => a.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = await _getDatabase();
    final maps = await db.query('apps', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return WebApp.fromMap(maps.first);
  }

  static Future<void> insertApp(WebApp app) async {
    await _ensureInitialized();
    if (kIsWeb) {
      _memoryStore.add(app);
      debugPrint('Inserted app: ${app.title}');
      return;
    }
    final db = await _getDatabase();
    await db.insert('apps', app.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('Inserted app: ${app.title}');
  }

  static Future<void> updateApp(WebApp app) async {
    await _ensureInitialized();
    app.updatedAt = DateTime.now();
    if (kIsWeb) {
      final index = _memoryStore.indexWhere((a) => a.id == app.id);
      if (index != -1) _memoryStore[index] = app;
      return;
    }
    final db = await _getDatabase();
    await db
        .update('apps', app.toMap(), where: 'id = ?', whereArgs: [app.id]);
  }

  static Future<void> deleteApp(String id) async {
    await _ensureInitialized();
    if (kIsWeb) {
      _memoryStore.removeWhere((a) => a.id == id);
      _memoryKvStore.remove(id);
      return;
    }
    final db = await _getDatabase();
    // Foreign key cascade will delete app_storage rows too
    await db.delete('apps', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════
  //  Prompts CRUD
  // ══════════════════════════════════════════

  static Future<List<AppPrompt>> getAllPrompts() async {
    await _ensureInitialized();
    if (kIsWeb) {
      return List.from(_memoryPrompts)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final db = await _getDatabase();
    final maps = await db.query('prompts', orderBy: 'updatedAt DESC');
    return maps.map((m) => AppPrompt.fromMap(m)).toList();
  }

  static Future<void> insertPrompt(AppPrompt prompt) async {
    await _ensureInitialized();
    if (kIsWeb) {
      _memoryPrompts.add(prompt);
      return;
    }
    final db = await _getDatabase();
    await db.insert('prompts', prompt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updatePrompt(AppPrompt prompt) async {
    await _ensureInitialized();
    prompt.updatedAt = DateTime.now();
    if (kIsWeb) {
      final index = _memoryPrompts.indexWhere((p) => p.id == prompt.id);
      if (index != -1) _memoryPrompts[index] = prompt;
      return;
    }
    final db = await _getDatabase();
    await db.update('prompts', prompt.toMap(),
        where: 'id = ?', whereArgs: [prompt.id]);
  }

  static Future<void> deletePrompt(String id) async {
    await _ensureInitialized();
    if (kIsWeb) {
      _memoryPrompts.removeWhere((p) => p.id == id);
      return;
    }
    final db = await _getDatabase();
    await db.delete('prompts', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════
  //  Per-App Key-Value Storage
  // ══════════════════════════════════════════

  static Future<String?> getStorageItem(String appId, String key) async {
    await _ensureInitialized();
    if (kIsWeb) {
      return _memoryKvStore[appId]?[key];
    }
    final db = await _getDatabase();
    final maps = await db.query('app_storage',
        where: 'appId = ? AND key = ?', whereArgs: [appId, key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  static Future<void> setStorageItem(
      String appId, String key, String value) async {
    await _ensureInitialized();
    if (kIsWeb) {
      _memoryKvStore.putIfAbsent(appId, () => {});
      _memoryKvStore[appId]![key] = value;
      return;
    }
    final db = await _getDatabase();
    await db.insert(
      'app_storage',
      {'appId': appId, 'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeStorageItem(String appId, String key) async {
    await _ensureInitialized();
    if (kIsWeb) {
      _memoryKvStore[appId]?.remove(key);
      return;
    }
    final db = await _getDatabase();
    await db.delete('app_storage',
        where: 'appId = ? AND key = ?', whereArgs: [appId, key]);
  }

  static Future<void> clearStorage(String appId) async {
    await _ensureInitialized();
    if (kIsWeb) {
      _memoryKvStore.remove(appId);
      return;
    }
    final db = await _getDatabase();
    await db
        .delete('app_storage', where: 'appId = ?', whereArgs: [appId]);
  }

  static Future<Map<String, String>> getAllStorageItems(String appId) async {
    await _ensureInitialized();
    if (kIsWeb) {
      return Map.from(_memoryKvStore[appId] ?? {});
    }
    final db = await _getDatabase();
    final maps = await db
        .query('app_storage', where: 'appId = ?', whereArgs: [appId]);
    return {for (final m in maps) m['key'] as String: m['value'] as String};
  }

  static Future<int> getStorageSize(String appId) async {
    await _ensureInitialized();
    if (kIsWeb) {
      final items = _memoryKvStore[appId] ?? {};
      int size = 0;
      for (final entry in items.entries) {
        size += entry.key.length + entry.value.length;
      }
      return size;
    }
    final db = await _getDatabase();
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(LENGTH(key) + LENGTH(value)), 0) as size FROM app_storage WHERE appId = ?',
      [appId],
    );
    return (result.first['size'] as int?) ?? 0;
  }
}
