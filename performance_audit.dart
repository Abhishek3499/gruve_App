import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PerformanceAudit {
  static final PerformanceAudit _instance = PerformanceAudit._internal();
  factory PerformanceAudit() => _instance;
  PerformanceAudit._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _durations = {};
  final Map<String, int> _rebuildCounts = {};
  
  // Startup performance tracking
  void startStartupTimer() {
    _startTimes['app_startup'] = DateTime.now();
    developer.log('🚀 [PERF] App startup timer started', name: 'PerformanceAudit');
  }

  void endStartupTimer() {
    if (_startTimes.containsKey('app_startup')) {
      final duration = DateTime.now().difference(_startTimes['app_startup']!);
      _recordDuration('app_startup', duration);
      developer.log('🚀 [PERF] App startup completed in ${duration.inMilliseconds}ms', name: 'PerformanceAudit');
    }
  }

  // Frame performance tracking
  void trackFrameBuild(String widgetName) {
    _rebuildCounts[widgetName] = (_rebuildCounts[widgetName] ?? 0) + 1;
    if (_rebuildCounts[widgetName]! % 10 == 0) {
      developer.log('🔄 [PERF] $widgetName rebuilt ${_rebuildCounts[widgetName]} times', name: 'PerformanceAudit');
    }
  }

  // API performance tracking
  void startApiCall(String endpoint) {
    _startTimes['api_$endpoint'] = DateTime.now();
    developer.log('🌐 [PERF] API call started: $endpoint', name: 'PerformanceAudit');
  }

  void endApiCall(String endpoint) {
    if (_startTimes.containsKey('api_$endpoint')) {
      final duration = DateTime.now().difference(_startTimes['api_$endpoint']!);
      _recordDuration('api_$endpoint', duration);
      developer.log('🌐 [PERF] API call completed: $endpoint in ${duration.inMilliseconds}ms', name: 'PerformanceAudit');
    }
  }

  // Image loading performance
  void startImageLoad(String imageUrl) {
    _startTimes['image_$imageUrl'] = DateTime.now();
  }

  void endImageLoad(String imageUrl) {
    if (_startTimes.containsKey('image_$imageUrl')) {
      final duration = DateTime.now().difference(_startTimes['image_$imageUrl']!);
      _recordDuration('image_loading', duration);
      developer.log('🖼️ [PERF] Image loaded in ${duration.inMilliseconds}ms: $imageUrl', name: 'PerformanceAudit');
    }
  }

  // Memory tracking
  void trackMemoryUsage(String context) {
    developer.log('💾 [PERF] Memory usage at $context: ${_getMemoryUsage()}', name: 'PerformanceAudit');
  }

  // Scroll performance tracking
  void startScrollPerformance(String listName) {
    _startTimes['scroll_$listName'] = DateTime.now();
    developer.log('📜 [PERF] Scroll started: $listName', name: 'PerformanceAudit');
  }

  void trackScrollFrame(String listName) {
    // Track scroll performance metrics
  }

  void endScrollPerformance(String listName) {
    if (_startTimes.containsKey('scroll_$listName')) {
      final duration = DateTime.now().difference(_startTimes['scroll_$listName']!);
      developer.log('📜 [PERF] Scroll ended: $listName in ${duration.inMilliseconds}ms', name: 'PerformanceAudit');
    }
  }

  // Camera performance tracking
  void startCameraStream() {
    _startTimes['camera_stream'] = DateTime.now();
    developer.log('📷 [PERF] Camera stream started', name: 'PerformanceAudit');
  }

  void trackCameraFrame() {
    // Track camera frame processing time
  }

  void endCameraStream() {
    if (_startTimes.containsKey('camera_stream')) {
      final duration = DateTime.now().difference(_startTimes['camera_stream']!);
      developer.log('📷 [PERF] Camera stream ended after ${duration.inMilliseconds}ms', name: 'PerformanceAudit');
    }
  }

  // Socket performance tracking
  void trackSocketEvent(String event) {
    developer.log('🔌 [PERF] Socket event: $event at ${DateTime.now().millisecondsSinceEpoch}', name: 'PerformanceAudit');
  }

  // Helper methods
  void _recordDuration(String operation, Duration duration) {
    _durations[operation] ??= [];
    _durations[operation]!.add(duration);
  }

  String _getMemoryUsage() {
    // This would require platform-specific implementation
    return 'N/A (requires platform integration)';
  }

  // Performance report generation
  void generatePerformanceReport() {
    developer.log('📊 [PERF] ========== PERFORMANCE REPORT ==========', name: 'PerformanceAudit');
    
    // Startup performance
    if (_durations.containsKey('app_startup')) {
      final startupTimes = _durations['app_startup']!;
      final avgStartup = startupTimes.reduce((a, b) => a + b).inMilliseconds / startupTimes.length;
      developer.log('🚀 [PERF] Average startup time: ${avgStartup.toStringAsFixed(2)}ms', name: 'PerformanceAudit');
    }

    // API performance
    _durations.forEach((key, durations) {
      if (key.startsWith('api_')) {
        final avgDuration = durations.reduce((a, b) => a + b).inMilliseconds / durations.length;
        developer.log('🌐 [PERF] API $key: Average ${avgDuration.toStringAsFixed(2)}ms (${durations.length} calls)', name: 'PerformanceAudit');
      }
    });

    // Image loading performance
    if (_durations.containsKey('image_loading')) {
      final imageTimes = _durations['image_loading']!;
      final avgImageTime = imageTimes.reduce((a, b) => a + b).inMilliseconds / imageTimes.length;
      developer.log('🖼️ [PERF] Average image load time: ${avgImageTime.toStringAsFixed(2)}ms', name: 'PerformanceAudit');
    }

    // Widget rebuild counts
    _rebuildCounts.forEach((widget, count) {
      developer.log('🔄 [PERF] $widget: Rebuilt $count times', name: 'PerformanceAudit');
    });

    developer.log('📊 [PERF] ========== END REPORT ==========', name: 'PerformanceAudit');
  }

  // Performance thresholds and warnings
  void checkPerformanceThresholds() {
    _durations.forEach((key, durations) {
      if (key.startsWith('api_')) {
        durations.forEach((duration) {
          if (duration.inMilliseconds > 2000) {
            developer.log('⚠️ [PERF] SLOW API: $key took ${duration.inMilliseconds}ms', name: 'PerformanceAudit');
          }
        });
      }
      
      if (key == 'image_loading') {
        durations.forEach((duration) {
          if (duration.inMilliseconds > 1000) {
            developer.log('⚠️ [PERF] SLOW IMAGE: Load took ${duration.inMilliseconds}ms', name: 'PerformanceAudit');
          }
        });
      }
    });

    _rebuildCounts.forEach((widget, count) {
      if (count > 50) {
        developer.log('⚠️ [PERF] EXCESSIVE REBUILDS: $widget rebuilt $count times', name: 'PerformanceAudit');
      }
    });
  }
}

// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String name;

  const PerformanceMonitor({super.key, required this.child, required this.name});

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final PerformanceAudit _audit = PerformanceAudit();

  @override
  Widget build(BuildContext context) {
    _audit.trackFrameBuild(widget.name);
    return widget.child;
  }
}

// Frame timing monitor
class FrameTimingMonitor {
  static void startMonitoring() {
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          if (timing.totalSpan.inMicroseconds > 16666) { // > 16.66ms = < 60 FPS
            developer.log('⚠️ [PERF] Frame drop: ${timing.totalSpan.inMicroseconds}μs', name: 'FrameTiming');
          }
        }
      });
    }
  }
}
