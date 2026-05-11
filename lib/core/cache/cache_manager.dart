import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gruve_app/core/debug/debug_logger.dart';

/// Cache entry with TTL support
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.ttl,
  }) : createdAt = DateTime.now();

  /// Check if cache entry is still valid
  bool get isValid => DateTime.now().difference(createdAt) < ttl;

  /// Check if cache entry is stale (expired but can be used for stale-while-revalidate)
  bool get isStale => !isValid;

  /// Get cache age
  Duration get age => DateTime.now().difference(createdAt);

  /// Serialize to JSON for disk storage
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'ttl': ttl.inMilliseconds,
    };
  }

  /// Deserialize from JSON
  factory CacheEntry.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return CacheEntry<T>(
      data: fromJson(json['data']),
      ttl: Duration(milliseconds: json['ttl']),
    );
  }
}

/// Cache configuration for different endpoint types
class CacheConfig {
  final Duration memoryTTL;
  final Duration diskTTL;
  final bool enableStaleWhileRevalidate;
  final int maxMemoryEntries;

  const CacheConfig({
    required this.memoryTTL,
    required this.diskTTL,
    this.enableStaleWhileRevalidate = true,
    this.maxMemoryEntries = 100,
  });

  /// Helper method to get data size
  int _getDataSize(dynamic data) {
    try {
      if (data == null) return 0;
      if (data is String) return (data as String).length;
      if (data is Map) return (data as Map).toString().length;
      if (data is List) return (data as List).toString().length;
      return data.toString().length;
    } catch (e) {
      return 0;
    }
  }
}

/// Predefined cache configurations
class CacheConfigs {
  static const feed = CacheConfig(
    memoryTTL: Duration(minutes: 2),
    diskTTL: Duration(minutes: 10),
    enableStaleWhileRevalidate: true,
    maxMemoryEntries: 50,
  );

  static const CacheConfig profile = CacheConfig(
    memoryTTL: Duration(minutes: 5),
    diskTTL: Duration(minutes: 30),
    enableStaleWhileRevalidate: true,
    maxMemoryEntries: 20,
  );

  static const CacheConfig stories = CacheConfig(
    memoryTTL: Duration(minutes: 1),
    diskTTL: Duration(minutes: 5),
    enableStaleWhileRevalidate: true,
    maxMemoryEntries: 30,
  );

  static const CacheConfig conversations = CacheConfig(
    memoryTTL: Duration(minutes: 3),
    diskTTL: Duration(minutes: 15),
    enableStaleWhileRevalidate: true,
    maxMemoryEntries: 25,
  );

  static const CacheConfig search = CacheConfig(
    memoryTTL: Duration(minutes: 1),
    diskTTL: Duration(minutes: 5),
    enableStaleWhileRevalidate: false,
    maxMemoryEntries: 40,
  );

  /// Get config based on endpoint path
  static CacheConfig getConfigForEndpoint(String path) {
    if (path.contains('/feed') || path.contains('/posts')) {
      return feed;
    } else if (path.contains('/profile') || path.contains('/user/')) {
      return profile;
    } else if (path.contains('/stories')) {
      return stories;
    } else if (path.contains('/conversations') || path.contains('/messages')) {
      return conversations;
    } else if (path.contains('/search')) {
      return search;
    }
    
    // Default config
    return const CacheConfig(
      memoryTTL: Duration(minutes: 2),
      diskTTL: Duration(minutes: 10),
    );
  }
}

/// Two-layer cache manager (memory + disk) with stale-while-revalidate
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  /// Memory cache storage
  final Map<String, CacheEntry> _memoryCache = {};

  /// SharedPreferences instance for disk cache
  SharedPreferences? _prefs;

  /// Background refresh operations
  final Map<String, Future<void>> _backgroundRefreshes = {};

  /// Initialize cache manager
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    debugPrint('🗄️ [CacheManager] Initialized');
  }

  /// Get cached data or null if not found/expired
  Future<T?> get<T>(
    String key,
    T Function(dynamic) fromJson,
    CacheConfig config,
  ) async {
    await initialize();

    // Try memory cache first
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && memoryEntry.isValid) {
      debugLog.cache('GET', key, 
        type: 'MEMORY', 
        hit: true, 
        size: _getDataSize(memoryEntry.data));
      return memoryEntry.data as T;
    }

    // Try disk cache if memory miss
    final diskEntry = await _getFromDisk<T>(key, fromJson);
    if (diskEntry != null && diskEntry.isValid) {
      // Promote to memory cache
      _memoryCache[key] = diskEntry;
      debugLog.cache('GET', key, 
        type: 'DISK', 
        hit: true, 
        size: _getDataSize(diskEntry.data));
      return diskEntry.data;
    }

    // Return stale data if stale-while-revalidate is enabled
    if (config.enableStaleWhileRevalidate) {
      final staleData = memoryEntry?.data ?? diskEntry?.data;
      if (staleData != null) {
        debugLog.cache('GET', key, 
          type: 'STALE', 
          hit: memoryEntry?.isValid == true ? true : diskEntry?.isValid == true ? true : false);
        return staleData as T;
      }
    }

    debugLog.cache('GET', key, type: 'MISS', hit: false);
    return null;
  }

  /// Put data in cache
  Future<void> put<T>(
    String key,
    T data,
    CacheConfig config, {
    T Function(dynamic)? toJson,
  }) async {
    await initialize();

    final entry = CacheEntry<T>(data: data, ttl: config.memoryTTL);
    _memoryCache[key] = entry;

    debugLog.cache('PUT', key, 
      type: 'MEMORY', 
      size: _getDataSize(data));

    // Store to disk if serializer is provided
    if (toJson != null) {
      await _putToDisk(key, entry, toJson);
    }

    // Cleanup old entries
    _cleanupMemoryCache(config.maxMemoryEntries);
  }

  /// Get data with stale-while-revalidate support
  Future<CacheResult<T>> getWithStaleRevalidate<T>(
    String key,
    T Function(dynamic) fromJson,
    CacheConfig config,
    Future<T> Function() refreshFunction, {
    T Function(dynamic)? toJson,
  }) async {
    await initialize();

    // Check if background refresh is already in progress
    if (_backgroundRefreshes.containsKey(key)) {
      debugPrint('⏳ [CacheManager] Background refresh in progress: $key');
      final cached = await get<T>(key, fromJson, config);
      return CacheResult<T>(
        data: cached,
        isFromCache: true,
        isStale: cached == null ? false : _isStale(key, config),
      );
    }

    // Try to get cached data
    final cached = await get<T>(key, fromJson, config);
    final isStale = cached != null && _isStale(key, config);

    // If data is stale and revalidate is enabled, start background refresh
    if (isStale && config.enableStaleWhileRevalidate) {
      _startBackgroundRefresh(key, refreshFunction, config, toJson);
    }

    return CacheResult<T>(
      data: cached,
      isFromCache: cached != null,
      isStale: isStale,
    );
  }

  /// Invalidate cache entry
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove(key);
    debugPrint('🗑️ [CacheManager] Invalidated: $key');
  }

  /// Invalidate cache entries by pattern
  Future<void> invalidatePattern(String pattern) async {
    final keysToRemove = <String>[];
    
    // Remove from memory cache
    _memoryCache.removeWhere((key, value) {
      if (key.contains(pattern)) {
        keysToRemove.add(key);
        return true;
      }
      return false;
    });

    // Remove from disk cache
    if (_prefs != null) {
      for (final key in _prefs!.getKeys()) {
        if (key.contains(pattern)) {
          keysToRemove.add(key);
          await _prefs!.remove(key);
        }
      }
    }

    debugPrint('🗑️ [CacheManager] Invalidated pattern "$pattern": ${keysToRemove.length} entries');
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    await _prefs?.clear();
    debugPrint('🧹 [CacheManager] Cleared all cache');
  }

  /// Get cache statistics
  CacheStats getStats() {
    return CacheStats(
      memorySize: _memoryCache.length,
      backgroundRefreshes: _backgroundRefreshes.length,
    );
  }

  // Private methods

  Future<CacheEntry<T>?> _getFromDisk<T>(
    String key,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final jsonString = _prefs?.getString(key);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CacheEntry.fromJson(json, fromJson);
    } catch (e) {
      debugPrint('❌ [CacheManager] Disk cache error for $key: $e');
      return null;
    }
  }

  Future<void> _putToDisk<T>(
    String key,
    CacheEntry<T> entry,
    T Function(dynamic) toJson,
  ) async {
    try {
      final json = entry.toJson();
      final jsonString = jsonEncode({
        ...json,
        'data': toJson(entry.data),
      });
      await _prefs?.setString(key, jsonString);
    } catch (e) {
      debugPrint('❌ [CacheManager] Disk cache write error for $key: $e');
    }
  }

  void _cleanupMemoryCache(int maxEntries) {
    if (_memoryCache.length <= maxEntries) return;

    // Sort by creation time and remove oldest
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    final toRemove = sortedEntries.length - maxEntries;
    for (int i = 0; i < toRemove; i++) {
      _memoryCache.remove(sortedEntries[i].key);
    }

    debugPrint('🧹 [CacheManager] Cleaned up $toRemove old memory entries');
  }

  bool _isStale(String key, CacheConfig config) {
    final entry = _memoryCache[key];
    if (entry == null) return false;
    return entry.isStale;
  }

  Future<void> _startBackgroundRefresh<T>(
    String key,
    Future<T> Function() refreshFunction,
    CacheConfig config,
    T Function(dynamic)? toJson,
  ) async {
    final refreshCompleter = Completer<void>();
    _backgroundRefreshes[key] = refreshCompleter.future;

    try {
      debugPrint('🔄 [CacheManager] Starting background refresh: $key');
      final freshData = await refreshFunction();
      await put(key, freshData, config, toJson: toJson);
      debugPrint('✅ [CacheManager] Background refresh completed: $key');
    } catch (e) {
      debugPrint('❌ [CacheManager] Background refresh failed: $key, error: $e');
    } finally {
      _backgroundRefreshes.remove(key);
      refreshCompleter.complete();
    }
  }

  /// Calculate approximate size of data in bytes
  int _getDataSize(dynamic data) {
    if (data == null) return 0;
    
    try {
      if (data is String) {
        return data.length;
      } else if (data is Map) {
        return jsonEncode(data).length;
      } else if (data is List) {
        return jsonEncode(data).length;
      } else {
        // For other types, use toString() as approximation
        return data.toString().length;
      }
    } catch (e) {
      // Fallback to string length if serialization fails
      return data.toString().length;
    }
  }
}

/// Cache result wrapper
class CacheResult<T> {
  final T? data;
  final bool isFromCache;
  final bool isStale;

  CacheResult({
    this.data,
    required this.isFromCache,
    required this.isStale,
  });

  bool get hasData => data != null;
}

/// Cache statistics
class CacheStats {
  final int memorySize;
  final int backgroundRefreshes;

  CacheStats({
    required this.memorySize,
    required this.backgroundRefreshes,
  });

  @override
  String toString() => 'CacheStats(memory: $memorySize, refreshing: $backgroundRefreshes)';
}
