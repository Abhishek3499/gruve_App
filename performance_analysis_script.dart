import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PerformanceAnalysisScript {
  static final PerformanceAnalysisScript _instance = PerformanceAnalysisScript._internal();
  factory PerformanceAnalysisScript() => _instance;
  PerformanceAnalysisScript._internal();

  // Performance metrics storage
  final Map<String, List<int>> _frameTimes = [];
  final Map<String, List<int>> _apiTimes = [];
  final Map<String, List<int>> _imageLoadTimes = [];
  final List<int> _startupTimes = [];
  final Map<String, int> _widgetRebuildCounts = {};
  final List<String> _performanceIssues = [];

  // Start comprehensive performance monitoring
  void startPerformanceMonitoring() {
    developer.log('🔍 [PERF ANALYSIS] Starting comprehensive performance monitoring', name: 'PerformanceAnalysis');
    
    // Monitor frame performance
    _monitorFramePerformance();
    
    // Monitor memory usage
    _monitorMemoryUsage();
    
    // Start periodic performance checks
    Timer.periodic(Duration(seconds: 10), (timer) {
      _generatePerformanceSnapshot();
    });
  }

  // Frame performance monitoring
  void _monitorFramePerformance() {
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final frameTime = timing.totalSpan.inMicroseconds;
        
        // Store frame time data
        _frameTimes['all_frames'] ??= [];
        _frameTimes['all_frames']!.add(frameTime);
        
        // Detect frame drops
        if (frameTime > 16666) { // > 16.66ms = < 60 FPS
          _performanceIssues.add('Frame drop: ${frameTime}μs');
          developer.log('⚠️ [PERF] Frame drop detected: ${frameTime}μs', name: 'FramePerformance');
        }
        
        // Detect severe frame drops
        if (frameTime > 33333) { // > 33.33ms = < 30 FPS
          _performanceIssues.add('Severe frame drop: ${frameTime}μs');
          developer.log('🚨 [PERF] Severe frame drop: ${frameTime}μs', name: 'FramePerformance');
        }
      }
    });
  }

  // Memory usage monitoring
  void _monitorMemoryUsage() {
    if (!kDebugMode) return;
    
    Timer.periodic(Duration(seconds: 5), (timer) {
      // This would require platform-specific implementation
      // For now, we'll log periodic memory checks
      developer.log('💾 [PERF] Memory check - ${DateTime.now()}', name: 'MemoryMonitor');
    });
  }

  // Track API performance
  void trackApiCall(String endpoint, int durationMs) {
    _apiTimes[endpoint] ??= [];
    _apiTimes[endpoint]!.add(durationMs);
    
    if (durationMs > 2000) {
      _performanceIssues.add('Slow API: $endpoint took ${durationMs}ms');
      developer.log('⚠️ [PERF] Slow API detected: $endpoint - ${durationMs}ms', name: 'ApiPerformance');
    }
    
    if (durationMs > 5000) {
      _performanceIssues.add('Very slow API: $endpoint took ${durationMs}ms');
      developer.log('🚨 [PERF] Very slow API: $endpoint - ${durationMs}ms', name: 'ApiPerformance');
    }
  }

  // Track image loading performance
  void trackImageLoad(String imageUrl, int durationMs) {
    _imageLoadTimes['all_images'] ??= [];
    _imageLoadTimes['all_images']!.add(durationMs);
    
    if (durationMs > 1000) {
      _performanceIssues.add('Slow image load: ${durationMs}ms');
      developer.log('⚠️ [PERF] Slow image load: ${durationMs}ms', name: 'ImagePerformance');
    }
  }

  // Track widget rebuilds
  void trackWidgetRebuild(String widgetName) {
    _widgetRebuildCounts[widgetName] = (_widgetRebuildCounts[widgetName] ?? 0) + 1;
    
    if (_widgetRebuildCounts[widgetName]! % 20 == 0) {
      developer.log('🔄 [PERF] $widgetName rebuilt ${_widgetRebuildCounts[widgetName]} times', name: 'WidgetRebuilds');
    }
    
    if (_widgetRebuildCounts[widgetName]! > 100) {
      _performanceIssues.add('Excessive rebuilds: $widgetName rebuilt ${_widgetRebuildCounts[widgetName]} times');
      developer.log('🚨 [PERF] Excessive rebuilds: $widgetName', name: 'WidgetRebuilds');
    }
  }

  // Track startup performance
  void trackStartupTime(int durationMs) {
    _startupTimes.add(durationMs);
    
    if (durationMs > 3000) {
      _performanceIssues.add('Slow startup: ${durationMs}ms');
      developer.log('⚠️ [PERF] Slow app startup: ${durationMs}ms', name: 'StartupPerformance');
    }
  }

  // Generate performance snapshot
  void _generatePerformanceSnapshot() {
    developer.log('📊 [PERF] ========== PERFORMANCE SNAPSHOT ==========', name: 'PerformanceAnalysis');
    
    // Frame performance
    if (_frameTimes['all_frames'] != null && _frameTimes['all_frames']!.isNotEmpty) {
      final frames = _frameTimes['all_frames']!;
      final avgFrameTime = frames.reduce((a, b) => a + b) / frames.length;
      final fps = 1000000 / avgFrameTime;
      developer.log('🎯 [PERF] Average FPS: ${fps.toStringAsFixed(1)}', name: 'PerformanceAnalysis');
      developer.log('📐 [PERF] Average frame time: ${(avgFrameTime / 1000).toStringAsFixed(2)}ms', name: 'PerformanceAnalysis');
      
      final droppedFrames = frames.where((time) => time > 16666).length;
      final droppedFramePercentage = (droppedFrames / frames.length) * 100;
      developer.log('⚠️ [PERF] Frame drops: ${droppedFramePercentage.toStringAsFixed(1)}%', name: 'PerformanceAnalysis');
    }
    
    // API performance
    _apiTimes.forEach((endpoint, times) {
      if (times.isNotEmpty) {
        final avgTime = times.reduce((a, b) => a + b) / times.length;
        developer.log('🌐 [PERF] $endpoint: Average ${avgTime.toStringAsFixed(0)}ms (${times.length} calls)', name: 'PerformanceAnalysis');
      }
    });
    
    // Image loading performance
    if (_imageLoadTimes['all_images'] != null && _imageLoadTimes['all_images']!.isNotEmpty) {
      final images = _imageLoadTimes['all_images']!;
      final avgTime = images.reduce((a, b) => a + b) / images.length;
      developer.log('🖼️ [PERF] Average image load: ${avgTime.toStringAsFixed(0)}ms (${images.length} images)', name: 'PerformanceAnalysis');
    }
    
    // Widget rebuilds
    _widgetRebuildCounts.forEach((widget, count) {
      if (count > 10) {
        developer.log('🔄 [PERF] $widget: $count rebuilds', name: 'PerformanceAnalysis');
      }
    });
    
    // Performance issues summary
    if (_performanceIssues.isNotEmpty) {
      developer.log('⚠️ [PERF] Issues detected: ${_performanceIssues.length}', name: 'PerformanceAnalysis');
      _performanceIssues.take(5).forEach((issue) {
        developer.log('  - $issue', name: 'PerformanceAnalysis');
      });
    }
    
    developer.log('📊 [PERF] ========== END SNAPSHOT ==========', name: 'PerformanceAnalysis');
  }

  // Generate comprehensive performance report
  void generateComprehensiveReport() {
    developer.log('📋 [PERF] ========== COMPREHENSIVE PERFORMANCE REPORT ==========', name: 'PerformanceAnalysis');
    
    // Startup performance
    if (_startupTimes.isNotEmpty) {
      final avgStartup = _startupTimes.reduce((a, b) => a + b) / _startupTimes.length;
      developer.log('🚀 [PERF] Startup Performance:', name: 'PerformanceAnalysis');
      developer.log('  Average: ${avgStartup.toStringAsFixed(0)}ms', name: 'PerformanceAnalysis');
      developer.log('  Range: ${_startupTimes.reduce((a, b) => a < b ? a : b)}ms - ${_startupTimes.reduce((a, b) => a > b ? a : b)}ms', name: 'PerformanceAnalysis');
    }
    
    // Frame performance analysis
    if (_frameTimes['all_frames'] != null && _frameTimes['all_frames']!.isNotEmpty) {
      final frames = _frameTimes['all_frames']!;
      final avgFrameTime = frames.reduce((a, b) => a + b) / frames.length;
      final fps = 1000000 / avgFrameTime;
      final droppedFrames = frames.where((time) => time > 16666).length;
      final severeDrops = frames.where((time) => time > 33333).length;
      
      developer.log('🎯 [PERF] Frame Performance:', name: 'PerformanceAnalysis');
      developer.log('  Average FPS: ${fps.toStringAsFixed(1)}', name: 'PerformanceAnalysis');
      developer.log('  Average frame time: ${(avgFrameTime / 1000).toStringAsFixed(2)}ms', name: 'PerformanceAnalysis');
      developer.log('  Dropped frames: ${droppedFrames} (${((droppedFrames / frames.length) * 100).toStringAsFixed(1)}%)', name: 'PerformanceAnalysis');
      developer.log('  Severe drops: $severeDrops', name: 'PerformanceAnalysis');
    }
    
    // API performance summary
    if (_apiTimes.isNotEmpty) {
      developer.log('🌐 [PERF] API Performance:', name: 'PerformanceAnalysis');
      _apiTimes.forEach((endpoint, times) {
        if (times.isNotEmpty) {
          final avg = times.reduce((a, b) => a + b) / times.length;
          final max = times.reduce((a, b) => a > b ? a : b);
          final slowCalls = times.where((time) => time > 2000).length;
          developer.log('  $endpoint:', name: 'PerformanceAnalysis');
          developer.log('    Average: ${avg.toStringAsFixed(0)}ms', name: 'PerformanceAnalysis');
          developer.log('    Max: ${max}ms', name: 'PerformanceAnalysis');
          developer.log('    Slow calls: $slowCalls/${times.length}', name: 'PerformanceAnalysis');
        }
      });
    }
    
    // Image loading summary
    if (_imageLoadTimes['all_images'] != null && _imageLoadTimes['all_images']!.isNotEmpty) {
      final images = _imageLoadTimes['all_images']!;
      final avgTime = images.reduce((a, b) => a + b) / images.length;
      final slowImages = images.where((time) => time > 1000).length;
      
      developer.log('🖼️ [PERF] Image Loading:', name: 'PerformanceAnalysis');
      developer.log('  Average: ${avgTime.toStringAsFixed(0)}ms', name: 'PerformanceAnalysis');
      developer.log('  Slow loads: $slowImages/${images.length}', name: 'PerformanceAnalysis');
    }
    
    // Widget rebuild analysis
    if (_widgetRebuildCounts.isNotEmpty) {
      developer.log('🔄 [PERF] Widget Rebuilds:', name: 'PerformanceAnalysis');
      final sortedRebuilds = _widgetRebuildCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      sortedRebuilds.take(10).forEach((entry) {
        developer.log('  ${entry.key}: ${entry.value}', name: 'PerformanceAnalysis');
      });
    }
    
    // Performance issues summary
    if (_performanceIssues.isNotEmpty) {
      developer.log('⚠️ [PERF] Performance Issues (${_performanceIssues.length}):', name: 'PerformanceAnalysis');
      _performanceIssues.forEach((issue) {
        developer.log('  - $issue', name: 'PerformanceAnalysis');
      });
    }
    
    // Performance recommendations
    _generateRecommendations();
    
    developer.log('📋 [PERF] ========== END REPORT ==========', name: 'PerformanceAnalysis');
  }

  // Generate performance recommendations
  void _generateRecommendations() {
    developer.log('💡 [PERF] Recommendations:', name: 'PerformanceAnalysis');
    
    // Frame performance recommendations
    if (_frameTimes['all_frames'] != null && _frameTimes['all_frames']!.isNotEmpty) {
      final frames = _frameTimes['all_frames']!;
      final droppedFrames = frames.where((time) => time > 16666).length;
      final droppedFramePercentage = (droppedFrames / frames.length) * 100;
      
      if (droppedFramePercentage > 10) {
        developer.log('  - Consider optimizing expensive widgets and reducing rebuilds', name: 'PerformanceAnalysis');
      }
      if (droppedFramePercentage > 20) {
        developer.log('  - High frame drop rate detected - investigate main thread blocking', name: 'PerformanceAnalysis');
      }
    }
    
    // API performance recommendations
    _apiTimes.forEach((endpoint, times) {
      if (times.isNotEmpty) {
        final avgTime = times.reduce((a, b) => a + b) / times.length;
        if (avgTime > 2000) {
          developer.log('  - Consider optimizing or caching $endpoint API calls', name: 'PerformanceAnalysis');
        }
      }
    });
    
    // Widget rebuild recommendations
    _widgetRebuildCounts.forEach((widget, count) {
      if (count > 50) {
        developer.log('  - $widget has excessive rebuilds - consider using const constructors or better state management', name: 'PerformanceAnalysis');
      }
    });
    
    // Startup performance recommendations
    if (_startupTimes.isNotEmpty) {
      final avgStartup = _startupTimes.reduce((a, b) => a + b) / _startupTimes.length;
      if (avgStartup > 3000) {
        developer.log('  - Consider optimizing app initialization and lazy loading', name: 'PerformanceAnalysis');
      }
    }
  }

  // Get performance metrics for external analysis
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'frameTimes': _frameTimes,
      'apiTimes': _apiTimes,
      'imageLoadTimes': _imageLoadTimes,
      'startupTimes': _startupTimes,
      'widgetRebuildCounts': _widgetRebuildCounts,
      'performanceIssues': _performanceIssues,
    };
  }
}

// Performance monitoring widget
class PerformanceMonitorWidget extends StatefulWidget {
  final Widget child;
  final String name;

  const PerformanceMonitorWidget({super.key, required this.child, required this.name});

  @override
  State<PerformanceMonitorWidget> createState() => _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget> {
  final PerformanceAnalysisScript _analyzer = PerformanceAnalysisScript();

  @override
  Widget build(BuildContext context) {
    _analyzer.trackWidgetRebuild(widget.name);
    return widget.child;
  }
}
