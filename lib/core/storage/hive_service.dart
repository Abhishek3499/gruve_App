import 'package:hive_flutter/hive_flutter.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// 🚀 Offline-First Caching Service
/// Handles initialization, storage, retrieval, and eviction of JSON-serialized responses.
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Box Names for cache isolation
  static const String userCacheBoxName = 'user_cache_box';
  static const String feedCacheBoxName = 'feed_cache_box';

  /// Initialize Hive and open caching boxes
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(userCacheBoxName);
      await Hive.openBox(feedCacheBoxName);
      AppLogger.d('📦 [HiveService] Hive initialized and cache boxes opened successfully.');
    } catch (e) {
      AppLogger.d('🚨 [HiveService] Initialization failed: $e');
    }
  }

  /// Cache data (usually JSON list or map) under a specific key in a box
  Future<void> cacheData(String boxName, String key, dynamic data) async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      final box = Hive.box(boxName);
      await box.put(key, data);
      AppLogger.d('✅ [HiveService] Cached data in box "$boxName" for key "$key"');
    } catch (e) {
      AppLogger.d('🚨 [HiveService] Failed to cache data in box "$boxName" for key "$key": $e');
    }
  }

  /// Retrieve cached data from a box
  dynamic getCachedData(String boxName, String key) {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        return null;
      }
      final box = Hive.box(boxName);
      final data = box.get(key);
      if (data != null) {
        AppLogger.d('📖 [HiveService] Cache HIT for key "$key" in box "$boxName"');
      } else {
        AppLogger.d('ℹ️ [HiveService] Cache MISS for key "$key" in box "$boxName"');
      }
      return data;
    } catch (e) {
      AppLogger.d('🚨 [HiveService] Failed to get cached data in box "$boxName" for key "$key": $e');
      return null;
    }
  }

  /// Evict/clear cache inside a specific box
  Future<void> clearCache(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.clear();
        AppLogger.d('🧹 [HiveService] Cache cleared for box "$boxName"');
      }
    } catch (e) {
      AppLogger.d('🚨 [HiveService] Failed to clear box "$boxName": $e');
    }
  }
}
