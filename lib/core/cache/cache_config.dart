import 'package:gruve_app/core/constants/api_constants.dart';

/// Cache configuration for different endpoints
/// Optimizes data loading with proper TTL and stale-while-revalidate strategy
class CacheConfigs {
  /// Get cache configuration for specific endpoint
  static CacheConfig getConfigForEndpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    // Feed/Posts endpoints - Cache for 5 minutes, serve stale for 10 minutes
    if (normalizedPath.contains(ApiConstants.getPost) ||
        normalizedPath.contains('feed/')) {
      return CacheConfig(
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: const Duration(minutes: 10),
        enableMemoryCache: true,
        enableDiskCache: true,
        maxMemorySize: 50 * 1024 * 1024, // 50MB for posts
        maxDiskSize: 200 * 1024 * 1024, // 200MB for posts
      );
    }

    // User profile - Cache for 3 minutes, serve stale for 5 minutes
    if (normalizedPath.contains('profile/') ||
        normalizedPath.contains('user/')) {
      return CacheConfig(
        ttl: const Duration(minutes: 3),
        staleWhileRevalidate: const Duration(minutes: 5),
        enableMemoryCache: true,
        enableDiskCache: true,
        maxMemorySize: 20 * 1024 * 1024, // 20MB for profiles
        maxDiskSize: 50 * 1024 * 1024, // 50MB for profiles
      );
    }

    // Messages/Conversations - Cache for 1 minute, serve stale for 2 minutes
    if (normalizedPath.contains('messages/') ||
        normalizedPath.contains('conversations/')) {
      return CacheConfig(
        ttl: const Duration(minutes: 1),
        staleWhileRevalidate: const Duration(minutes: 2),
        enableMemoryCache: true,
        enableDiskCache: false, // Don't persist messages to disk
        maxMemorySize: 10 * 1024 * 1024, // 10MB for messages
      );
    }

    // Search results - Cache for 2 minutes, serve stale for 5 minutes
    if (normalizedPath.contains('search/')) {
      return CacheConfig(
        ttl: const Duration(minutes: 2),
        staleWhileRevalidate: const Duration(minutes: 5),
        enableMemoryCache: true,
        enableDiskCache: true,
        maxMemorySize: 15 * 1024 * 1024, // 15MB for search
        maxDiskSize: 30 * 1024 * 1024, // 30MB for search
      );
    }

    // Notifications - Cache for 30 seconds, serve stale for 1 minute
    if (normalizedPath.contains('notifications/')) {
      return CacheConfig(
        ttl: const Duration(seconds: 30),
        staleWhileRevalidate: const Duration(minutes: 1),
        enableMemoryCache: true,
        enableDiskCache: false, // Don't persist notifications
        maxMemorySize: 5 * 1024 * 1024, // 5MB for notifications
      );
    }

    // Stories - Cache for 10 minutes, serve stale for 20 minutes
    if (normalizedPath.contains('stories/') ||
        normalizedPath.contains('highlights/')) {
      return CacheConfig(
        ttl: const Duration(minutes: 10),
        staleWhileRevalidate: const Duration(minutes: 20),
        enableMemoryCache: true,
        enableDiskCache: true,
        maxMemorySize: 30 * 1024 * 1024, // 30MB for stories
        maxDiskSize: 100 * 1024 * 1024, // 100MB for stories
      );
    }

    // Saved posts - Cache for 5 minutes, serve stale for 15 minutes
    if (normalizedPath.contains('posts/saved')) {
      return CacheConfig(
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: const Duration(minutes: 15),
        enableMemoryCache: true,
        enableDiskCache: true,
        maxMemorySize: 20 * 1024 * 1024, // 20MB for saved posts
        maxDiskSize: 50 * 1024 * 1024, // 50MB for saved posts
      );
    }

    // Comments - Cache for 2 minutes, serve stale for 3 minutes
    if (normalizedPath.contains('comments/')) {
      return CacheConfig(
        ttl: const Duration(minutes: 2),
        staleWhileRevalidate: const Duration(minutes: 3),
        enableMemoryCache: true,
        enableDiskCache: false, // Don't persist comments
        maxMemorySize: 10 * 1024 * 1024, // 10MB for comments
      );
    }

    // Default configuration for other endpoints
    return CacheConfig.defaultConfig();
  }

  /// Get default cache configuration
  static CacheConfig getDefaultConfig() {
    return CacheConfig(
      ttl: const Duration(minutes: 5),
      staleWhileRevalidate: const Duration(minutes: 10),
      enableMemoryCache: true,
      enableDiskCache: true,
      maxMemorySize: 25 * 1024 * 1024, // 25MB default
      maxDiskSize: 100 * 1024 * 1024, // 100MB default
    );
  }
}

/// Cache configuration model
class CacheConfig {
  final Duration ttl;
  final Duration staleWhileRevalidate;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final int maxMemorySize;
  final int maxDiskSize;

  const CacheConfig({
    required this.ttl,
    required this.staleWhileRevalidate,
    required this.enableMemoryCache,
    required this.enableDiskCache,
    this.maxMemorySize = 25 * 1024 * 1024, // 25MB default
    this.maxDiskSize = 100 * 1024 * 1024, // 100MB default
  });

  /// Default configuration
  factory CacheConfig.defaultConfig() {
    return const CacheConfig(
      ttl: Duration(minutes: 5),
      staleWhileRevalidate: Duration(minutes: 10),
      enableMemoryCache: true,
      enableDiskCache: true,
      maxMemorySize: 25 * 1024 * 1024,
      maxDiskSize: 100 * 1024 * 1024,
    );
  }

  /// No cache configuration (for sensitive data)
  factory CacheConfig.noCache() {
    return const CacheConfig(
      ttl: Duration.zero,
      staleWhileRevalidate: Duration.zero,
      enableMemoryCache: false,
      enableDiskCache: false,
      maxMemorySize: 0,
      maxDiskSize: 0,
    );
  }

  /// Short-lived cache (30 seconds)
  factory CacheConfig.shortLived() {
    return const CacheConfig(
      ttl: Duration(seconds: 30),
      staleWhileRevalidate: Duration(minutes: 1),
      enableMemoryCache: true,
      enableDiskCache: false,
      maxMemorySize: 5 * 1024 * 1024,
    );
  }

  /// Long-lived cache (30 minutes)
  factory CacheConfig.longLived() {
    return const CacheConfig(
      ttl: Duration(minutes: 30),
      staleWhileRevalidate: Duration(hours: 1),
      enableMemoryCache: true,
      enableDiskCache: true,
      maxMemorySize: 50 * 1024 * 1024,
      maxDiskSize: 200 * 1024 * 1024,
    );
  }

  /// Check if cache is enabled
  bool get isEnabled => enableMemoryCache || enableDiskCache;

  /// Check if TTL is valid
  bool get hasValidTtl => ttl.inSeconds > 0;

  /// Get cache key prefix based on configuration
  String getCacheKeyPrefix() {
    if (!isEnabled) return 'nocache';
    if (ttl.inMinutes < 1) return 'short';
    if (ttl.inMinutes >= 30) return 'long';
    return 'medium';
  }
}
