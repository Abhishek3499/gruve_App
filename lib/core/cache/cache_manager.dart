import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gruve_app/core/debug/debug_logger.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Cache entry with TTL support
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.ttl,
  }) : createdAt = DateTime.now();

  CacheEntry._({
    required this.data,
    required this.ttl,
    required this.createdAt,
  });

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
  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return CacheEntry<T>._(
      data: fromJson(json['data']),
      ttl: Duration(milliseconds: json['ttl']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] is int ? json['createdAt'] as int : 0,
      ),
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

  String _getPrefixedKey(String key) => 'http_cache_$key';

  /// Initialize cache manager
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    AppLogger.d('🗄️ [CacheManager] Initialized');
  }

  /// Get cached data or null if not found/expired with enhanced logging
  Future<T?> get<T>(
    String key,
    T Function(dynamic) fromJson,
    CacheConfig config,
  ) async {
    await initialize();

    AppLogger.d('🔍 [CacheManager] Getting cache for key: $key');

    // Try memory cache first
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null) {
      if (memoryEntry.isValid) {
        debugLog.cache('GET', key, 
          type: 'MEMORY', 
          hit: true, 
          size: _getDataSize(memoryEntry.data));
        return memoryEntry.data as T;
      } else {
        AppLogger.d('⏰ [CacheManager] Memory cache entry expired for $key (age: ${memoryEntry.age.inSeconds}s, ttl: ${memoryEntry.ttl.inSeconds}s)');
      }
    } else {
      AppLogger.d('🔍 [CacheManager] No memory cache entry for $key');
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
    } else if (diskEntry != null) {
      AppLogger.d('⏰ [CacheManager] Disk cache entry expired for $key (age: ${diskEntry.age.inSeconds}s, ttl: ${diskEntry.ttl.inSeconds}s)');
    } else {
      AppLogger.d('🔍 [CacheManager] No disk cache entry for $key');
    }

    // Return stale data if stale-while-revalidate is enabled
    if (config.enableStaleWhileRevalidate) {
      final staleData = memoryEntry?.data ?? diskEntry?.data;
      if (staleData != null) {
        debugLog.cache('GET', key, 
          type: 'STALE', 
          hit: memoryEntry?.isValid == true || diskEntry?.isValid == true,
          size: _getDataSize(staleData));
        return staleData as T;
      }
    }

    debugLog.cache('GET', key, type: 'MISS', hit: false);
    return null;
  }

  /// Put data in cache with enhanced logging and memory optimization
  Future<void> put<T>(
    String key,
    T data,
    CacheConfig config, {
    T Function(dynamic)? toJson,
  }) async {
    await initialize();

    final dataSize = _getDataSize(data);
    
    // Memory optimization: Check if we're approaching limits
    if (_memoryCache.length >= config.maxMemoryEntries) {
      AppLogger.d('⚠️ [CacheManager] Memory cache full (${_memoryCache.length}/${config.maxMemoryEntries}), triggering cleanup before put');
      _cleanupMemoryCache(config.maxMemoryEntries - 1); // Make space
    }

    final entry = CacheEntry<T>(data: data, ttl: config.memoryTTL);
    _memoryCache[key] = entry;

    AppLogger.d('💾 [CacheManager] PUT $key (MEMORY, size: ${dataSize}B, entries: ${_memoryCache.length})');

    // Store to disk if serializer is provided and data is not too large
    if (toJson != null && dataSize < 1024 * 1024) { // 1MB limit for disk cache
      await _putToDisk(key, entry, toJson);
    } else if (dataSize >= 1024 * 1024) {
      AppLogger.d('⚠️ [CacheManager] Skipping disk cache for large data (${(dataSize / 1024 / 1024).toStringAsFixed(2)}MB): $key');
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
      AppLogger.d('⏳ [CacheManager] Background refresh in progress: $key');
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
    AppLogger.d('🗑️ [CacheManager] Invalidated: $key');
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

    AppLogger.d('🗑️ [CacheManager] Invalidated pattern "$pattern": ${keysToRemove.length} entries');
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
    AppLogger.d('🧹 [CacheManager] Cleared all cache starting with http_cache_');
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
        : Duration(milliseconds: _memoryCache.entries
            .map((e) => e.value.age.inMilliseconds)
            .reduce((a, b) => a + b) ~/ _memoryCache.length);

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
      AppLogger.d('❌ [CacheManager] Disk cache error for $key: $e');
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
      await _prefs?.setString(_getPrefixedKey(key), jsonString);
    } catch (e) {
      AppLogger.d('❌ [CacheManager] Disk cache write error for $key: $e');
    }
  }

  void _cleanupMemoryCache(int maxEntries) {
    if (_memoryCache.length <= maxEntries) {
      AppLogger.d('🧹 [CacheManager] No cleanup needed (${_memoryCache.length}/$maxEntries entries)');
      return;
    }

    // Sort by creation time and remove oldest
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    final toRemove = sortedEntries.length - maxEntries;
    final removedKeys = <String>[];
    
    for (int i = 0; i < toRemove; i++) {
      final entry = sortedEntries[i];
      final age = entry.value.age;
      final size = _getDataSize(entry.value.data);
      removedKeys.add(entry.key);
      _memoryCache.remove(entry.key);
      AppLogger.d('🗑️ [CacheManager] Removed old entry: ${entry.key} (age: ${age.inSeconds}s, size: ${size}B)');
    }

    AppLogger.d('🧹 [CacheManager] Cleaned up $toRemove old memory entries. Remaining: ${_memoryCache.length}/$maxEntries');
    AppLogger.d('🧹 [CacheManager] Removed keys: ${removedKeys.join(', ')}');
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
      AppLogger.d('🔄 [CacheManager] Starting background refresh: $key');
      final freshData = await refreshFunction();
      await put(key, freshData, config, toJson: toJson);
      AppLogger.d('✅ [CacheManager] Background refresh completed: $key');
    } catch (e) {
      AppLogger.d('❌ [CacheManager] Background refresh failed: $key, error: $e');
    } finally {
      _backgroundRefreshes.remove(key);
      refreshCompleter.complete();
    }
  }

  /// Calculate approximate size of data in bytes with enhanced logging
  int _getDataSize(dynamic data) {
    if (data == null) {
      AppLogger.d('📏 [CacheManager] Data is null, size: 0 bytes');
      return 0;
    }
    
    int size;
    String type;
    
    try {
      if (data is String) {
        size = data.length;
        type = 'String';
      } else if (data is Map) {
        final jsonString = jsonEncode(data);
        size = jsonString.length;
        type = 'Map(${data.length} keys)';
      } else if (data is List) {
        final jsonString = jsonEncode(data);
        size = jsonString.length;
        type = 'List(${data.length} items)';
      } else if (data.toString().contains('CacheData')) {
        // Handle CacheData type checking without direct import
        size = 100; // Estimated size for wrapper objects
        type = 'CacheData';
      } else {
        // For other types, use toString() as approximation
        final stringRep = data.toString();
        size = stringRep.length;
        type = data.runtimeType.toString();
      }
      
      AppLogger.d('📏 [CacheManager] Data size calculated: $size bytes for type $type');
      return size;
    } catch (e) {
      // Fallback to string length if serialization fails
      final fallbackSize = data.toString().length;
      AppLogger.d('⚠️ [CacheManager] Size calculation failed for ${data.runtimeType}: $e, using fallback: $fallbackSize bytes');
      return fallbackSize;
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

/// Enhanced cache statistics with detailed metrics
class CacheStats {
  final int memorySize;
  final int backgroundRefreshes;
  final int totalMemorySizeBytes;
  final int expiredEntries;
  final Duration averageAge;
  final List<String> inFlightRequests;

  CacheStats({
    required this.memorySize,
    required this.backgroundRefreshes,
    required this.totalMemorySizeBytes,
    required this.expiredEntries,
    required this.averageAge,
    required this.inFlightRequests,
  });

  /// Get memory size in human readable format
  String get memorySizeFormatted {
    if (totalMemorySizeBytes < 1024) return '${totalMemorySizeBytes}B';
    if (totalMemorySizeBytes < 1024 * 1024) return '${(totalMemorySizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(totalMemorySizeBytes / 1024 / 1024).toStringAsFixed(1)}MB';
  }

  /// Get average age in human readable format
  String get averageAgeFormatted {
    if (averageAge.inSeconds < 60) return '${averageAge.inSeconds}s';
    if (averageAge.inMinutes < 60) return '${averageAge.inMinutes}m ${averageAge.inSeconds % 60}s';
    return '${averageAge.inHours}h ${averageAge.inMinutes % 60}m';
  }

  @override
  String toString() {
    return 'CacheStats('
           'entries: $memorySize, '
           'size: $memorySizeFormatted, '
           'expired: $expiredEntries, '
           'avgAge: $averageAgeFormatted, '
           'refreshing: $backgroundRefreshes, '
           'inFlight: ${inFlightRequests.length})';
  }
}
