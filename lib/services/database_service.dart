import 'package:flutter/foundation.dart';
import '../models/web_app.dart';

/// Platform-adaptive database service.
/// Uses in-memory storage for web, SQLite for native platforms.
class DatabaseService {
  static final List<WebApp> _memoryStore = [];
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    // For web, we just use in-memory storage.
    // For native platforms, we'd use sqflite — but sqflite doesn't support web.
    // TODO: Add sqflite backend for Android/iOS/desktop builds.
    debugPrint('DatabaseService initialized (${kIsWeb ? "web/memory" : "native"})');
  }

  static Future<List<WebApp>> getAllApps() async {
    await _ensureInitialized();
    return List.from(_memoryStore)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<WebApp?> getAppById(String id) async {
    await _ensureInitialized();
    try {
      return _memoryStore.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> insertApp(WebApp app) async {
    await _ensureInitialized();
    _memoryStore.add(app);
    debugPrint('Inserted app: ${app.title}');
  }

  static Future<void> updateApp(WebApp app) async {
    await _ensureInitialized();
    app.updatedAt = DateTime.now();
    final index = _memoryStore.indexWhere((a) => a.id == app.id);
    if (index != -1) {
      _memoryStore[index] = app;
    }
  }

  static Future<void> deleteApp(String id) async {
    await _ensureInitialized();
    _memoryStore.removeWhere((a) => a.id == id);
  }
}
