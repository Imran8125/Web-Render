import 'database_service.dart';

/// High-level service for managing per-app key-value storage.
/// Wraps DatabaseService's app_storage table operations.
class StorageService {
  final String appId;

  const StorageService(this.appId);

  Future<String?> getItem(String key) =>
      DatabaseService.getStorageItem(appId, key);

  Future<void> setItem(String key, String value) =>
      DatabaseService.setStorageItem(appId, key, value);

  Future<void> removeItem(String key) =>
      DatabaseService.removeStorageItem(appId, key);

  Future<void> clear() => DatabaseService.clearStorage(appId);

  Future<Map<String, String>> getAllItems() =>
      DatabaseService.getAllStorageItems(appId);

  Future<int> getStorageSize() => DatabaseService.getStorageSize(appId);

  /// Returns a human-readable size string (e.g. "1.2 KB").
  Future<String> getFormattedSize() async {
    final bytes = await getStorageSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
