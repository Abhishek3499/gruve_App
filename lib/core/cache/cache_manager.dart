import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

import 'package:gruve_app/core/cache/cache_entry.dart';
import 'package:gruve_app/core/cache/cache_configs.dart';
import 'package:gruve_app/core/cache/cache_stats.dart';

export 'package:gruve_app/core/cache/cache_entry.dart';
export 'package:gruve_app/core/cache/cache_configs.dart';
export 'package:gruve_app/core/cache/cache_stats.dart';

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

  String _getPrefixedKey(String key) => 'http_cache_$key';

  /// Initialize cache manager
  Future<void> initialize() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    AppLogger.debug('CacheManager', 'initialized');
  }

  /// Get cached data or null if not found/expired with enhanced logging
  Future<T?> get<T>(
    String key,
    T Function(dynamic) fromJson,
    CacheConfig config,
  ) async {
    await initialize();

    // 1. Check memory cache
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && memoryEntry.isValid) {
      return memoryEntry.data as T;
    }

    // 2. Check disk cache
    final diskEntry = await _getFromDisk<T>(key, fromJson);
    if (diskEntry != null && diskEntry.isValid) {
      _memoryCache[key] = diskEntry;
      return diskEntry.data;
    }

    // 3. Stale fallback if enabled
    if (config.enableStaleWhileRevalidate) {
      final staleData = memoryEntry?.data ?? diskEntry?.data;
      if (staleData != null) {
        return staleData as T;
      }
    }

    return null;
  }

  /// Put data in cache with enhanced logging and memory optimization
  Future<void> put<T>(
    String key,
    T data,
    CacheConfig config, {
    dynamic Function(T)? toJson,
  }) async {
    await initialize();

    final dataSize = _getDataSize(data);

    // Memory optimization: Check if we're approaching limits
    if (_memoryCache.length >= config.maxMemoryEntries) {
      _cleanupMemoryCache(config.maxMemoryEntries - 1); // Make space
    }

    final entry = CacheEntry<T>(data: data, ttl: config.memoryTTL);
    _memoryCache[key] = entry;

    AppLogger.debug(
      'CacheManager',
      'cache_put',
      data: {'key': key, 'sizeBytes': dataSize, 'entries': _memoryCache.length},
    );

    // Store to disk if serializer is provided and data is not too large
    if (toJson != null && dataSize < 1024 * 1024) {
      // 1MB limit for disk cache
      await _putToDisk(key, entry, toJson);
    } else if (dataSize >= 1024 * 1024) {
      AppLogger.debug(
        'CacheManager',
        'disk_cache_skipped',
        data: {'key': key, 'sizeMb': double.parse((dataSize / 1024 / 1024).toStringAsFixed(2))},
      );
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
    dynamic Function(T)? toJson,
  }) async {
    await initialize();

    // Check if background refresh is already in progress
    if (_backgroundRefreshes.containsKey(key)) {
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
    await initialize();
    _memoryCache.remove(key);
    await _prefs?.remove(_getPrefixedKey(key));
    AppLogger.debug('CacheManager', 'cache_invalidated', data: {'key': key});
  }

  /// Invalidate cache entries by pattern
  Future<void> invalidatePattern(String pattern) async {
    await initialize();
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
        if (key.startsWith('http_cache_') && key.contains(pattern)) {
          keysToRemove.add(key);
          await _prefs!.remove(key);
        }
      }
    }

    AppLogger.debug(
      'CacheManager',
      'cache_pattern_invalidated',
      data: {'pattern': pattern, 'entries': keysToRemove.length},
    );
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    if (_prefs != null) {
      final keysToRemove = <String>[];
      for (final key in _prefs!.getKeys()) {
        if (key.startsWith('http_cache_')) {
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        await _prefs!.remove(key);
      }
    }
    AppLogger.debug('CacheManager', 'cache_cleared');
  }

  /// Get comprehensive cache statistics
  CacheStats getStats() {
    final totalMemorySize = _memoryCache.entries
        .map((e) => _getDataSize(e.value.data))
        .fold<int>(0, (sum, size) => sum + size);

    final expiredEntries = _memoryCache.entries
        .where((e) => !e.value.isValid)
        .length;

    final averageAge = _memoryCache.isEmpty
        ? Duration.zero
        : Duration(
            milliseconds:
                _memoryCache.entries
                    .map((e) => e.value.age.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                _memoryCache.length,
          );

    return CacheStats(
      memorySize: _memoryCache.length,
      backgroundRefreshes: _backgroundRefreshes.length,
      totalMemorySizeBytes: totalMemorySize,
      expiredEntries: expiredEntries,
      averageAge: averageAge,
      inFlightRequests: _backgroundRefreshes.keys.toList(),
    );
  }

  // Private methods

  Future<CacheEntry<T>?> _getFromDisk<T>(
    String key,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final jsonString = _prefs?.getString(_getPrefixedKey(key));
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CacheEntry.fromJson(json, fromJson);
    } catch (e) {
      AppLogger.warning('CacheManager', 'disk_read_failed', data: {'key': key, 'error': e.toString()});
      return null;
    }
  }

  Future<void> _putToDisk<T>(
    String key,
    CacheEntry<T> entry,
    dynamic Function(T) toJson,
  ) async {
    try {
      final json = entry.toJson();
      final jsonString = jsonEncode({...json, 'data': toJson(entry.data)});
      await _prefs?.setString(_getPrefixedKey(key), jsonString);
    } catch (e) {
      AppLogger.warning('CacheManager', 'disk_write_failed', data: {'key': key, 'error': e.toString()});
    }
  }

  void _cleanupMemoryCache(int maxEntries) {
    if (_memoryCache.length <= maxEntries) {
      return;
    }

    // Sort by creation time and remove oldest
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    final toRemove = sortedEntries.length - maxEntries;
    final removedKeys = <String>[];

    for (int i = 0; i < toRemove; i++) {
      final entry = sortedEntries[i];
      removedKeys.add(entry.key);
      _memoryCache.remove(entry.key);
    }

    AppLogger.debug(
      'CacheManager',
      'cache_cleanup',
      data: {
        'removed': toRemove,
        'remaining': _memoryCache.length,
        'maxEntries': maxEntries,
        'removedKeys': removedKeys,
      },
    );
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
    dynamic Function(T)? toJson,
  ) async {
    final refreshCompleter = Completer<void>();
    _backgroundRefreshes[key] = refreshCompleter.future;

    try {
      final freshData = await refreshFunction();
      await put(key, freshData, config, toJson: toJson);
      AppLogger.debug('CacheManager', 'background_refresh_completed', data: {'key': key});
    } catch (e) {
      AppLogger.warning(
        'CacheManager',
        'background_refresh_failed',
        data: {'key': key, 'error': e.toString()},
      );
    } finally {
      _backgroundRefreshes.remove(key);
      refreshCompleter.complete();
    }
  }

  /// Calculate approximate size of data in bytes with enhanced logging
  int _getDataSize(dynamic data) {
    if (data == null) {
      return 0;
    }

    try {
      if (data is String) {
        return data.length;
      } else if (data is Map) {
        return jsonEncode(data).length;
      } else if (data is List) {
        return jsonEncode(data).length;
      } else if (data.toString().contains('CacheData')) {
        // Handle CacheData type checking without direct import
        return 100; // Estimated size for wrapper objects
      } else {
        // For other types, use toString() as approximation
        return data.toString().length;
      }
    } catch (e) {
      // Fallback to string length if serialization fails
      final fallbackSize = data.toString().length;
      AppLogger.debug(
        'CacheManager',
        'size_calc_fallback',
        data: {'type': data.runtimeType.toString(), 'error': e.toString(), 'fallbackSize': fallbackSize},
      );
      return fallbackSize;
    }
  }
}
