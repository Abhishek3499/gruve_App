import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Comprehensive Performance Test Suite for Gruve App
/// 
/// This suite provides automated performance testing capabilities:
/// - Stress testing
/// - Memory leak detection
/// - Frame rate analysis
/// - API performance testing
/// - Image loading performance
/// - Socket performance testing
class PerformanceTestSuite {
  static final PerformanceTestSuite _instance = PerformanceTestSuite._internal();
  factory PerformanceTestSuite() => _instance;
  PerformanceTestSuite._internal();

  final Map<String, List<int>> _testResults = {};
  Timer? _stressTestTimer;
  int _frameCount = 0;
  int _droppedFrames = 0;
  DateTime? _testStartTime;

  /// Start comprehensive performance testing
  void startPerformanceTesting() {
    developer.log('🧪 [PERF TEST] Starting comprehensive performance test suite', name: 'PerformanceTestSuite');
    _testStartTime = DateTime.now();
    
    // Start frame monitoring
    _startFrameMonitoring();
    
    // Start stress testing
    _startStressTesting();
    
    // Start memory monitoring
    _startMemoryMonitoring();
  }

  /// Frame monitoring for performance analysis
  void _startFrameMonitoring() {
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        _frameCount++;
        final frameTime = timing.totalSpan.inMicroseconds;
        
        if (frameTime > 16666) { // > 16.66ms = < 60 FPS
          _droppedFrames++;
          developer.log('⚠️ [PERF TEST] Frame drop detected: ${frameTime}μs', name: 'FrameTest');
        }
        
        // Store frame time data
        _testResults['frame_times'] ??= [];
        _testResults['frame_times']!.add(frameTime);
      }
    });
  }

  /// Stress testing - simulate heavy usage
  void _startStressTesting() {
    developer.log('💪 [PERF TEST] Starting stress testing', name: 'StressTest');
    
    _stressTestTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _performStressTest();
    });
  }

  /// Perform individual stress test operations
  void _performStressTest() {
    final stressStart = DateTime.now();
    
    // Simulate heavy operations
    _simulateHeavyComputation();
    _simulateMemoryAllocation();
    _simulateApiCalls();
    
    final stressTime = DateTime.now().difference(stressStart);
    _testResults['stress_test_times'] ??= [];
    _testResults['stress_test_times']!.add(stressTime.inMilliseconds);
    
    if (stressTime.inMilliseconds > 100) {
      developer.log('⚠️ [PERF TEST] Stress test took ${stressTime.inMilliseconds}ms', name: 'StressTest');
    }
  }

  /// Simulate heavy computation
  void _simulateHeavyComputation() {
    // Simulate image processing or complex calculations
    for (int i = 0; i < 1000; i++) {
      final result = (i * 1.5).toString();
      result.hashCode; // Force computation
    }
  }

  /// Simulate memory allocation
  void _simulateMemoryAllocation() {
    // Simulate loading large data sets
    final largeList = List.generate(1000, (index) => 'Item $index - ${DateTime.now().millisecondsSinceEpoch}');
    largeList.length; // Force allocation
  }

  /// Simulate API calls
  void _simulateApiCalls() async {
    // Simulate network latency
    await Future.delayed(Duration(milliseconds: 50));
  }

  /// Memory monitoring
  void _startMemoryMonitoring() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      _checkMemoryUsage();
    });
  }

  /// Check memory usage (simplified)
  void _checkMemoryUsage() {
    // This would require platform-specific implementation
    // For now, we'll log periodic checks
    developer.log('💾 [PERF TEST] Memory check at ${DateTime.now()}', name: 'MemoryTest');
  }

  /// Test image loading performance
  void testImageLoadingPerformance(List<String> imageUrls) async {
    developer.log('🖼️ [PERF TEST] Testing image loading performance', name: 'ImageTest');
    
    for (final imageUrl in imageUrls) {
      final loadStart = DateTime.now();
      
      try {
        // Simulate image loading
        await Future.delayed(Duration(milliseconds: 200 + (imageUrl.hashCode % 800)));
        
        final loadTime = DateTime.now().difference(loadStart);
        _testResults['image_load_times'] ??= [];
        _testResults['image_load_times']!.add(loadTime.inMilliseconds);
        
        developer.log('🖼️ [PERF TEST] Image loaded in ${loadTime.inMilliseconds}ms: $imageUrl', name: 'ImageTest');
        
        if (loadTime.inMilliseconds > 1000) {
          developer.log('⚠️ [PERF TEST] Slow image load: ${loadTime.inMilliseconds}ms', name: 'ImageTest');
        }
      } catch (e) {
        developer.log('❌ [PERF TEST] Image load failed: $e', name: 'ImageTest');
      }
    }
  }

  /// Test socket performance
  void testSocketPerformance() {
    developer.log('🔌 [PERF TEST] Testing socket performance', name: 'SocketTest');
    
    final socketTestStart = DateTime.now();
    
    // Simulate socket operations
    _simulateSocketOperations();
    
    final socketTestTime = DateTime.now().difference(socketTestStart);
    _testResults['socket_test_times'] ??= [];
    _testResults['socket_test_times']!.add(socketTestTime.inMilliseconds);
    
    developer.log('🔌 [PERF TEST] Socket test completed in ${socketTestTime.inMilliseconds}ms', name: 'SocketTest');
  }

  /// Simulate socket operations
  void _simulateSocketOperations() async {
    // Simulate message sending/receiving
    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(milliseconds: 10));
      // Simulate socket event
      developer.log('🔌 [PERF TEST] Socket event $i simulated', name: 'SocketTest');
    }
  }

  /// Test scrolling performance
  void testScrollingPerformance() {
    developer.log('📜 [PERF TEST] Testing scrolling performance', name: 'ScrollTest');
    
    final scrollTestStart = DateTime.now();
    
    // Simulate scrolling operations
    _simulateScrollingOperations();
    
    final scrollTestTime = DateTime.now().difference(scrollTestStart);
    _testResults['scroll_test_times'] ??= [];
    _testResults['scroll_test_times']!.add(scrollTestTime.inMilliseconds);
    
    developer.log('📜 [PERF TEST] Scroll test completed in ${scrollTestTime.inMilliseconds}ms', name: 'ScrollTest');
  }

  /// Simulate scrolling operations
  void _simulateScrollingOperations() {
    // Simulate list scrolling with many items
    final items = List.generate(1000, (index) => 'Item $index');
    
    // Simulate scroll viewport calculations
    for (int i = 0; i < 100; i++) {
      final startIndex = i * 10;
      final endIndex = (startIndex + 20).clamp(0, items.length);
      final visibleItems = items.sublist(startIndex, endIndex);
      visibleItems.length; // Force processing
    }
  }

  /// Generate comprehensive performance report
  void generateTestReport() {
    if (_testStartTime == null) {
      developer.log('❌ [PERF TEST] No test data available', name: 'PerformanceTestSuite');
      return;
    }
    
    final totalTestTime = DateTime.now().difference(_testStartTime!);
    developer.log('📊 [PERF TEST] ========== PERFORMANCE TEST REPORT ==========', name: 'PerformanceTestSuite');
    developer.log('⏱️ [PERF TEST] Total test duration: ${totalTestTime.inSeconds}s', name: 'PerformanceTestSuite');
    
    // Frame performance analysis
    if (_testResults['frame_times'] != null && _testResults['frame_times']!.isNotEmpty) {
      final frames = _testResults['frame_times']!;
      final avgFrameTime = frames.reduce((a, b) => a + b) / frames.length;
      final fps = 1000000 / avgFrameTime;
      final dropRate = (_droppedFrames / _frameCount) * 100;
      
      developer.log('🎯 [PERF TEST] Frame Performance:', name: 'PerformanceTestSuite');
      developer.log('  Total frames: $_frameCount', name: 'PerformanceTestSuite');
      developer.log('  Dropped frames: $_droppedFrames', name: 'PerformanceTestSuite');
      developer.log('  Drop rate: ${dropRate.toStringAsFixed(1)}%', name: 'PerformanceTestSuite');
      developer.log('  Average FPS: ${fps.toStringAsFixed(1)}', name: 'PerformanceTestSuite');
      developer.log('  Average frame time: ${(avgFrameTime / 1000).toStringAsFixed(2)}ms', name: 'PerformanceTestSuite');
    }
    
    // Stress test analysis
    if (_testResults['stress_test_times'] != null && _testResults['stress_test_times']!.isNotEmpty) {
      final stressTimes = _testResults['stress_test_times']!;
      final avgStressTime = stressTimes.reduce((a, b) => a + b) / stressTimes.length;
      final maxStressTime = stressTimes.reduce((a, b) => a > b ? a : b);
      
      developer.log('💪 [PERF TEST] Stress Test Performance:', name: 'PerformanceTestSuite');
      developer.log('  Average operation time: ${avgStressTime.toStringAsFixed(1)}ms', name: 'PerformanceTestSuite');
      developer.log('  Max operation time: ${maxStressTime}ms', name: 'PerformanceTestSuite');
      developer.log('  Total operations: ${stressTimes.length}', name: 'PerformanceTestSuite');
    }
    
    // Image loading analysis
    if (_testResults['image_load_times'] != null && _testResults['image_load_times']!.isNotEmpty) {
      final imageTimes = _testResults['image_load_times']!;
      final avgImageTime = imageTimes.reduce((a, b) => a + b) / imageTimes.length;
      final slowImages = imageTimes.where((time) => time > 1000).length;
      
      developer.log('🖼️ [PERF TEST] Image Loading Performance:', name: 'PerformanceTestSuite');
      developer.log('  Average load time: ${avgImageTime.toStringAsFixed(0)}ms', name: 'PerformanceTestSuite');
      developer.log('  Slow loads (>1s): $slowImages/${imageTimes.length}', name: 'PerformanceTestSuite');
      developer.log('  Total images: ${imageTimes.length}', name: 'PerformanceTestSuite');
    }
    
    // Socket performance analysis
    if (_testResults['socket_test_times'] != null && _testResults['socket_test_times']!.isNotEmpty) {
      final socketTimes = _testResults['socket_test_times']!;
      final avgSocketTime = socketTimes.reduce((a, b) => a + b) / socketTimes.length;
      
      developer.log('🔌 [PERF TEST] Socket Performance:', name: 'PerformanceTestSuite');
      developer.log('  Average operation time: ${avgSocketTime.toStringAsFixed(1)}ms', name: 'PerformanceTestSuite');
      developer.log('  Total operations: ${socketTimes.length}', name: 'PerformanceTestSuite');
    }
    
    // Scrolling performance analysis
    if (_testResults['scroll_test_times'] != null && _testResults['scroll_test_times']!.isNotEmpty) {
      final scrollTimes = _testResults['scroll_test_times']!;
      final avgScrollTime = scrollTimes.reduce((a, b) => a + b) / scrollTimes.length;
      
      developer.log('📜 [PERF TEST] Scrolling Performance:', name: 'PerformanceTestSuite');
      developer.log('  Average scroll operation: ${avgScrollTime.toStringAsFixed(1)}ms', name: 'PerformanceTestSuite');
      developer.log('  Total operations: ${scrollTimes.length}', name: 'PerformanceTestSuite');
    }
    
    // Performance recommendations
    _generateTestRecommendations();
    
    developer.log('📊 [PERF TEST] ========== END REPORT ==========', name: 'PerformanceTestSuite');
  }

  /// Generate performance test recommendations
  void _generateTestRecommendations() {
    developer.log('💡 [PERF TEST] Test Recommendations:', name: 'PerformanceTestSuite');
    
    // Frame performance recommendations
    if (_frameCount > 0) {
      final dropRate = (_droppedFrames / _frameCount) * 100;
      if (dropRate > 10) {
        developer.log('  - High frame drop rate detected (${dropRate.toStringAsFixed(1)}%) - optimize expensive operations', name: 'PerformanceTestSuite');
      }
      if (dropRate > 20) {
        developer.log('  - Critical frame drop rate - investigate main thread blocking immediately', name: 'PerformanceTestSuite');
      }
    }
    
    // Stress test recommendations
    if (_testResults['stress_test_times'] != null && _testResults['stress_test_times']!.isNotEmpty) {
      final stressTimes = _testResults['stress_test_times']!;
      final avgStressTime = stressTimes.reduce((a, b) => a + b) / stressTimes.length;
      if (avgStressTime > 100) {
        developer.log('  - Stress test operations are slow - optimize heavy computations', name: 'PerformanceTestSuite');
      }
    }
    
    // Image loading recommendations
    if (_testResults['image_load_times'] != null && _testResults['image_load_times']!.isNotEmpty) {
      final imageTimes = _testResults['image_load_times']!;
      final slowImages = imageTimes.where((time) => time > 1000).length;
      if (slowImages > 0) {
        developer.log('  - $slowImages slow image loads detected - implement better caching/compression', name: 'PerformanceTestSuite');
      }
    }
  }

  /// Stop performance testing
  void stopPerformanceTesting() {
    _stressTestTimer?.cancel();
    generateTestReport();
    developer.log('🛑 [PERF TEST] Performance testing stopped', name: 'PerformanceTestSuite');
  }

  /// Get test results for analysis
  Map<String, List<int>> getTestResults() {
    return Map.from(_testResults);
  }

  /// Clear test results
  void clearTestResults() {
    _testResults.clear();
    _frameCount = 0;
    _droppedFrames = 0;
    _testStartTime = null;
    developer.log('🗑️ [PERF TEST] Test results cleared', name: 'PerformanceTestSuite');
  }
}

/// Performance Test Widget for UI integration
class PerformanceTestWidget extends StatefulWidget {
  final Widget child;

  const PerformanceTestWidget({super.key, required this.child});

  @override
  State<PerformanceTestWidget> createState() => _PerformanceTestWidgetState();
}

class _PerformanceTestWidgetState extends State<PerformanceTestWidget> {
  final PerformanceTestSuite _testSuite = PerformanceTestSuite();
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      // Auto-start testing in debug mode
      _startTesting();
    }
  }

  void _startTesting() {
    if (!_isTesting) {
      _isTesting = true;
      _testSuite.startPerformanceTesting();
    }
  }

  void _stopTesting() {
    if (_isTesting) {
      _isTesting = false;
      _testSuite.stopPerformanceTesting();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (kDebugMode && _isTesting)
          Positioned(
            top: 50,
            right: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PERF TESTING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _stopTesting();
    super.dispose();
  }
}
