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
