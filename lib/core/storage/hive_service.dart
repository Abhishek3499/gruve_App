import 'package:hive_flutter/hive_flutter.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// 📦 HiveService
/// A lightweight, offline-first local cache service for fast data storage and retrieval.
class HiveService {
  // Singleton instance
  static final HiveService _instance = HiveService._internal();
  static HiveService get instance => _instance;
  factory HiveService() => _instance;
  HiveService._internal();

  // ==========================================
  // Cache Box Names
  // ==========================================
  static const String userCacheBoxName = 'user_cache_box';
  static const String feedCacheBoxName = 'feed_cache_box';

  /// 🚀 1. Initialize Hive and open default cache boxes
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(userCacheBoxName);
      await Hive.openBox(feedCacheBoxName);
      AppLogger.d('📦 [HiveService] Initialized and default boxes opened successfully.');
    } catch (e) {
      AppLogger.d('🚨 [HiveService] Initialization failed: $e');
    }
  }

  /// 💾 2. Save / Cache data by key
  Future<void> cacheData(String boxName, String key, dynamic data) async {
    try {
      final box = await _openBoxIfNeeded(boxName);
      await box.put(key, data);
      AppLogger.d('✅ [HiveService] Cached "$key" in [$boxName]');
    } catch (e) {
      AppLogger.d('🚨 [HiveService] Failed to cache "$key" in [$boxName]: $e');
    }
  }

  /// 📖 3. Get cached data by key (returns null if not found)
  dynamic getCachedData(String boxName, String key) {
    try {
      if (!Hive.isBoxOpen(boxName)) return null;

      final box = Hive.box(boxName);
      final data = box.get(key);

      if (data != null) {
        AppLogger.d('📖 [HiveService] Cache HIT for "$key" in [$boxName]');
      } else {
        AppLogger.d('ℹ️ [HiveService] Cache MISS for "$key" in [$boxName]');
      }
      return data;
    } catch (e) {
      AppLogger.d('🚨 [HiveService] Failed to read "$key" from [$boxName]: $e');
      return null;
    }
  }

  /// 🗑️ 4. Delete a specific key from a box
  Future<void> evictCachedData(String boxName, String key) async {
    try {
      if (!Hive.isBoxOpen(boxName)) return;

      final box = Hive.box(boxName);
      await box.delete(key);
      AppLogger.d('🧹 [HiveService] Deleted key "$key" from [$boxName]');
    } catch (e) {
      AppLogger.d('🚨 [HiveService] Failed to delete key "$key" from [$boxName]: $e');
    }
  }

  /// 🧹 5. Clear all data inside a specific box (e.g. on Logout)
  Future<void> clearCache(String boxName) async {
    try {
      if (!Hive.isBoxOpen(boxName)) return;

      final box = Hive.box(boxName);
      await box.clear();
      AppLogger.d('🧹 [HiveService] Cleared all data in [$boxName]');
    } catch (e) {
      AppLogger.d('🚨 [HiveService] Failed to clear box [$boxName]: $e');
    }
  }

  // ==========================================
  // Helper Methods
  // ==========================================

  /// Safely gets or opens a box if it is not currently open
  Future<Box> _openBoxIfNeeded(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }
}
