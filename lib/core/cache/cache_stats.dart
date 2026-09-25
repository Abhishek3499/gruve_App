/// Cache result wrapper
class CacheResult<T> {
  final T? data;
  final bool isFromCache;
  final bool isStale;

  CacheResult({this.data, required this.isFromCache, required this.isStale});

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
    if (totalMemorySizeBytes < 1024) {
      return '${totalMemorySizeBytes}B';
    }
    if (totalMemorySizeBytes < 1024 * 1024) {
      return '${(totalMemorySizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(totalMemorySizeBytes / 1024 / 1024).toStringAsFixed(1)}MB';
  }

  /// Get average age in human readable format
  String get averageAgeFormatted {
    if (averageAge.inSeconds < 60) {
      return '${averageAge.inSeconds}s';
    }
    if (averageAge.inMinutes < 60) {
      return '${averageAge.inMinutes}m ${averageAge.inSeconds % 60}s';
    }
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
