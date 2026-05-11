import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance monitoring and optimization utilities
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal() {
    _initializeFrameMonitoring();
  }

  // =========================
  // FRAME MONITORING
  // =========================

  final List<int> _frameTimes = [];
  Timer? _cleanupTimer;
  int _droppedFrames = 0;
  int _totalFrames = 0;

  void _initializeFrameMonitoring() {
    if (!kDebugMode) return;

    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        _totalFrames++;
        final frameTime = timing.totalSpan.inMicroseconds;
        _frameTimes.add(frameTime);

        // 60 FPS = 16,666μs per frame
        if (frameTime > 16666) {
          _droppedFrames++;
          developer.log(
            '⚠️ [PERF] Frame drop: ${frameTime}μs (${(frameTime / 16666).toStringAsFixed(1)}x frame time)',
            name: 'PerformanceOptimizer',
          );
        }
      }
    });

    // Cleanup old frame times every 10 seconds
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_frameTimes.length > 600) { // Keep last 10 seconds at 60fps
        _frameTimes.removeRange(0, _frameTimes.length - 600);
      }
    });
  }

  /// Get current performance metrics
  PerformanceMetrics getMetrics() {
    if (_frameTimes.isEmpty) {
      return PerformanceMetrics(
        averageFrameTime: 0,
        droppedFrameRate: 0.0,
        totalFrames: _totalFrames,
        droppedFrames: _droppedFrames,
      );
    }

    final averageFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final droppedFrameRate = _totalFrames > 0 ? _droppedFrames / _totalFrames : 0.0;

    return PerformanceMetrics(
      averageFrameTime: averageFrameTime,
      droppedFrameRate: droppedFrameRate,
      totalFrames: _totalFrames,
      droppedFrames: _droppedFrames,
    );
  }

  // =========================
  // WIDGET OPTIMIZATION HELPERS
  // =========================

  /// Wrap heavy list items with RepaintBoundary
  static Widget optimizeListItem(Widget child) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// Add const constructor optimization
  static Widget constOptimized(Widget child) {
    return child;
  }

  /// Debounce rapid actions
  static Timer? _debounceTimer;
  static void debounce(VoidCallback action, Duration delay) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, action);
  }

  /// Throttle scroll events
  static Timer? _throttleTimer;
  static bool _isThrottled = false;
  static void throttle(VoidCallback action, Duration delay) {
    if (_isThrottled) return;
    
    _isThrottled = true;
    action();
    
    _throttleTimer = Timer(delay, () {
      _isThrottled = false;
    });
  }

  // =========================
  // MEMORY OPTIMIZATION
  // =========================

  /// Clear image cache
  static Future<void> clearImageCache() async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      developer.log('🧹 [PERF] Image cache cleared', name: 'PerformanceOptimizer');
    } catch (e) {
      developer.log('❌ [PERF] Error clearing image cache: $e', name: 'PerformanceOptimizer');
    }
  }

  /// Set image cache size
  static void setImageCacheSize({int size = 1000}) {
    PaintingBinding.instance.imageCache.maximumSize = size;
    developer.log('⚙️ [PERF] Image cache size set to $size', name: 'PerformanceOptimizer');
  }

  // =========================
  // PROFILING HELPERS
  // =========================

  /// Profile a function execution time
  static T profileFunction<T>(String name, T Function() function) {
    if (!kDebugMode) return function();
    
    final stopwatch = Stopwatch()..start();
    try {
      return function();
    } finally {
      stopwatch.stop();
      developer.log(
        '⏱️ [PERF] $name: ${stopwatch.elapsedMilliseconds}ms',
        name: 'PerformanceOptimizer',
      );
    }
  }

  /// Profile async function execution time
  static Future<T> profileAsyncFunction<T>(String name, Future<T> Function() function) async {
    if (!kDebugMode) return await function();
    
    final stopwatch = Stopwatch()..start();
    try {
      return await function();
    } finally {
      stopwatch.stop();
      developer.log(
        '⏱️ [PERF] $name: ${stopwatch.elapsedMilliseconds}ms',
        name: 'PerformanceOptimizer',
      );
    }
  }

  // =========================
  // DISPOSE
  // =========================

  void dispose() {
    _cleanupTimer?.cancel();
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();
  }
}

/// Performance metrics data class
class PerformanceMetrics {
  final double averageFrameTime;
  final double droppedFrameRate;
  final int totalFrames;
  final int droppedFrames;

  PerformanceMetrics({
    required this.averageFrameTime,
    required this.droppedFrameRate,
    required this.totalFrames,
    required this.droppedFrames,
  });

  double get averageFPS => averageFrameTime > 0 ? 1000000 / averageFrameTime : 0.0;
  
  double get smoothness => 1.0 - droppedFrameRate;

  @override
  String toString() {
    return 'PerformanceMetrics('
        'FPS: ${averageFPS.toStringAsFixed(1)}, '
        'Dropped: ${(droppedFrameRate * 100).toStringAsFixed(1)}%, '
        'Total: $totalFrames'
        ')';
  }
}

/// Extension for easy performance profiling
extension PerformanceProfiler on Widget {
  /// Wrap widget with performance monitoring
  Widget withProfile(String name) {
    if (!kDebugMode) return this;
    
    return PerformanceOverlay(
      enabled: true,
      child: this,
    );
  }
}

/// Optimized list view builder
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      // Use extent-based builder for better performance
      cacheExtent: 250.0, // Cache ~1.5 screens worth of items
      addAutomaticKeepAlives: false, // Disable keep alives for better memory
      addRepaintBoundaries: true, // Enable repaint boundaries
      addSemanticIndexes: true, // Keep semantics for accessibility
      itemBuilder: (context, index) {
        return PerformanceOptimizer.optimizeListItem(
          itemBuilder(context, index),
        );
      },
    );
  }
}

/// Optimized grid view builder
class OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      cacheExtent: 250.0,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        return PerformanceOptimizer.optimizeListItem(
          itemBuilder(context, index),
        );
      },
    );
  }
}
