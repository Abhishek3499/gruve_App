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

  /// Returns the cache config for [path], or `null` if this endpoint isn't
  /// explicitly allow-listed for caching.
  ///
  /// Caching here is opt-in, not opt-out: an endpoint that isn't matched
  /// below always goes straight to the network. This used to fall back to a
  /// generic 2min/10min default for *any* unmatched GET, which silently
  /// cached endpoints nobody decided should be cached (e.g. the close
  /// friends connections list), causing stale-data bugs after writes that
  /// had no reason to know a read they'd never heard of was being cached.
  /// Add a new bucket here only when you've deliberately decided that
  /// endpoint's data is safe to serve stale for a while.
  static CacheConfig? getConfigForEndpoint(String path) {
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

    return null;
  }
}
