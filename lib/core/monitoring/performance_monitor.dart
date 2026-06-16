import 'package:gruve_app/core/utils/app_logger.dart';

/// Performance monitoring utility
/// Tracks and logs slow API calls, video loads, and other performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Performance thresholds (in milliseconds)
  static const int slowApiThreshold = 3000; // 3 seconds
  static const int verySlowApiThreshold = 5000; // 5 seconds
  static const int slowVideoThreshold = 10000; // 10 seconds
  static const int verySlowVideoThreshold = 20000; // 20 seconds

  // Statistics tracking
  final Map<String, List<Duration>> _apiTimings = {};
  final Map<String, List<Duration>> _videoTimings = {};
  int _totalApiCalls = 0;
  int _slowApiCalls = 0;
  int _failedApiCalls = 0;
  int _totalVideoLoads = 0;
  int _slowVideoLoads = 0;
  int _failedVideoLoads = 0;

  /// Log API call timing
  void logApiTiming(String endpoint, Duration duration, {bool failed = false}) {
    _totalApiCalls++;
    
    if (failed) {
      _failedApiCalls++;
      AppLogger.d('❌ FAILED API: $endpoint');
      return;
    }

    // Track timing
    _apiTimings.putIfAbsent(endpoint, () => []);
    _apiTimings[endpoint]!.add(duration);

    final milliseconds = duration.inMilliseconds;
    
    if (milliseconds > verySlowApiThreshold) {
      _slowApiCalls++;
      AppLogger.d('🐌 VERY SLOW API: $endpoint took ${duration.inSeconds}s (>${verySlowApiThreshold}ms)');
    } else if (milliseconds > slowApiThreshold) {
      _slowApiCalls++;
      AppLogger.d('⚠️ SLOW API: $endpoint took ${duration.inSeconds}s (>${slowApiThreshold}ms)');
    } else if (milliseconds > 1000) {
      AppLogger.d('⏱️ API: $endpoint took ${duration.inSeconds}s');
    } else {
      AppLogger.d('✅ FAST API: $endpoint took ${milliseconds}ms');
    }
  }

  /// Log video load timing
  void logVideoLoadTime(String videoUrl, Duration duration, {bool failed = false}) {
    _totalVideoLoads++;
    
    if (failed) {
      _failedVideoLoads++;
      AppLogger.d('❌ FAILED VIDEO: ${_sanitizeUrl(videoUrl)}');
      return;
    }

    // Track timing
    final key = 'video_load';
    _videoTimings.putIfAbsent(key, () => []);
    _videoTimings[key]!.add(duration);

    final seconds = duration.inSeconds;
    final milliseconds = duration.inMilliseconds;
    
    if (milliseconds > verySlowVideoThreshold) {
      _slowVideoLoads++;
      AppLogger.d('🐌 VERY SLOW VIDEO: ${_sanitizeUrl(videoUrl)} took ${seconds}s (>${verySlowVideoThreshold / 1000}s)');
    } else if (milliseconds > slowVideoThreshold) {
      _slowVideoLoads++;
      AppLogger.d('⚠️ SLOW VIDEO: ${_sanitizeUrl(videoUrl)} took ${seconds}s (>${slowVideoThreshold / 1000}s)');
    } else if (seconds > 3) {
      AppLogger.d('⏱️ VIDEO: ${_sanitizeUrl(videoUrl)} took ${seconds}s');
    } else {
      AppLogger.d('✅ FAST VIDEO: ${_sanitizeUrl(videoUrl)} took ${seconds}s');
    }
  }

  /// Log page load timing
  void logPageLoadTime(String pageName, Duration duration) {
    final milliseconds = duration.inMilliseconds;
    
    if (milliseconds > 2000) {
      AppLogger.d('⚠️ SLOW PAGE: $pageName took ${duration.inSeconds}s to load');
    } else if (milliseconds > 1000) {
      AppLogger.d('⏱️ PAGE: $pageName took ${duration.inSeconds}s to load');
    } else {
      AppLogger.d('✅ FAST PAGE: $pageName took ${milliseconds}ms to load');
    }
  }

  /// Log memory usage
  void logMemoryWarning(String context, int usedMB, int limitMB) {
    final percentage = (usedMB / limitMB * 100).toStringAsFixed(1);
    
    if (usedMB >= limitMB) {
      AppLogger.d('🔴 MEMORY CRITICAL: $context using ${usedMB}MB (${percentage}% of ${limitMB}MB limit)');
    } else if (usedMB >= limitMB * 0.8) {
      AppLogger.d('⚠️ MEMORY HIGH: $context using ${usedMB}MB (${percentage}% of ${limitMB}MB limit)');
    } else if (usedMB >= limitMB * 0.6) {
      AppLogger.d('⏱️ MEMORY MEDIUM: $context using ${usedMB}MB (${percentage}% of ${limitMB}MB limit)');
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getStatistics() {
    final avgApiTime = _calculateAverage(_apiTimings.values.expand((list) => list));
    final avgVideoTime = _calculateAverage(_videoTimings.values.expand((list) => list));

    return {
      'api': {
        'total_calls': _totalApiCalls,
        'slow_calls': _slowApiCalls,
        'failed_calls': _failedApiCalls,
        'success_rate': _totalApiCalls > 0 
            ? (((_totalApiCalls - _failedApiCalls) / _totalApiCalls) * 100).toStringAsFixed(1) + '%'
            : 'N/A',
        'avg_time_ms': avgApiTime?.inMilliseconds ?? 0,
        'slowest_endpoints': _getSlowestEndpoints(),
      },
      'video': {
        'total_loads': _totalVideoLoads,
        'slow_loads': _slowVideoLoads,
        'failed_loads': _failedVideoLoads,
        'success_rate': _totalVideoLoads > 0 
            ? (((_totalVideoLoads - _failedVideoLoads) / _totalVideoLoads) * 100).toStringAsFixed(1) + '%'
            : 'N/A',
        'avg_time_s': avgVideoTime?.inSeconds ?? 0,
      },
    };
  }

  /// Print performance report
  void printReport() {
    final stats = getStatistics();
    
    AppLogger.d('\n📊 ===== PERFORMANCE REPORT =====');
    AppLogger.d('API Calls:');
    AppLogger.d('  Total: ${stats['api']['total_calls']}');
    AppLogger.d('  Slow: ${stats['api']['slow_calls']}');
    AppLogger.d('  Failed: ${stats['api']['failed_calls']}');
    AppLogger.d('  Success Rate: ${stats['api']['success_rate']}');
    AppLogger.d('  Avg Time: ${stats['api']['avg_time_ms']}ms');
    
    AppLogger.d('\nVideo Loads:');
    AppLogger.d('  Total: ${stats['video']['total_loads']}');
    AppLogger.d('  Slow: ${stats['video']['slow_loads']}');
    AppLogger.d('  Failed: ${stats['video']['failed_loads']}');
    AppLogger.d('  Success Rate: ${stats['video']['success_rate']}');
    AppLogger.d('  Avg Time: ${stats['video']['avg_time_s']}s');
    
    if (stats['api']['slowest_endpoints'] != null) {
      AppLogger.d('\nSlowest Endpoints:');
      for (final entry in (stats['api']['slowest_endpoints'] as List)) {
        AppLogger.d('  ${entry['endpoint']}: ${entry['avg_ms']}ms');
      }
    }
    
    AppLogger.d('===== END REPORT =====\n');
  }

  /// Reset statistics
  void reset() {
    _apiTimings.clear();
    _videoTimings.clear();
    _totalApiCalls = 0;
    _slowApiCalls = 0;
    _failedApiCalls = 0;
    _totalVideoLoads = 0;
    _slowVideoLoads = 0;
    _failedVideoLoads = 0;
    
    AppLogger.d('🔄 Performance statistics reset');
  }

  // Private helper methods

  Duration? _calculateAverage(Iterable<Duration> durations) {
    if (durations.isEmpty) return null;
    
    final totalMs = durations.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  List<Map<String, dynamic>> _getSlowestEndpoints() {
    if (_apiTimings.isEmpty) return [];

    final averages = <Map<String, dynamic>>[];
    
    for (final entry in _apiTimings.entries) {
      if (entry.value.isEmpty) continue;
      
      final avg = _calculateAverage(entry.value);
      if (avg != null && avg.inMilliseconds > slowApiThreshold) {
        averages.add({
          'endpoint': entry.key,
          'avg_ms': avg.inMilliseconds,
          'count': entry.value.length,
        });
      }
    }

    // Sort by average time (slowest first)
    averages.sort((a, b) => (b['avg_ms'] as int).compareTo(a['avg_ms'] as int));
    
    // Return top 5
    return averages.take(5).toList();
  }

  String _sanitizeUrl(String url) {
    // Show only filename and extension, not full URL
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return url.split('/').last;
    } catch (e) {
      return 'unknown';
    }
  }
}

/// Extension for easy timing measurement
extension PerformanceTimingExtension on Stopwatch {
  /// Start timing and return the stopwatch
  Stopwatch startTiming() {
    start();
    return this;
  }

  /// Stop timing and log API call
  void stopAndLogApi(String endpoint, {bool failed = false}) {
    stop();
    PerformanceMonitor().logApiTiming(endpoint, elapsed, failed: failed);
  }

  /// Stop timing and log video load
  void stopAndLogVideo(String videoUrl, {bool failed = false}) {
    stop();
    PerformanceMonitor().logVideoLoadTime(videoUrl, elapsed, failed: failed);
  }

  /// Stop timing and log page load
  void stopAndLogPage(String pageName) {
    stop();
    PerformanceMonitor().logPageLoadTime(pageName, elapsed);
  }
}
