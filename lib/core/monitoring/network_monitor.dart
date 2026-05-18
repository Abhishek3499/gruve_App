import 'package:flutter/foundation.dart';

/// Network monitoring utility
/// Tracks API calls, response times, and errors
class NetworkMonitor {
  static final NetworkMonitor _instance = NetworkMonitor._internal();
  factory NetworkMonitor() => _instance;
  NetworkMonitor._internal();
  
  int _totalApiCalls = 0;
  int _successfulCalls = 0;
  int _failedCalls = 0;
  final Map<String, int> _endpointCalls = {};
  final Map<String, Duration> _endpointAvgTimes = {};
  final Map<String, int> _endpointErrors = {};
  
  int get totalApiCalls => _totalApiCalls;
  int get successfulCalls => _successfulCalls;
  int get failedCalls => _failedCalls;
  
  void logApiCall({
    required String method,
    required String endpoint,
    required Duration duration,
    required int statusCode,
    String? error,
  }) {
    if (!kDebugMode) return;
    
    _totalApiCalls++;
    
    if (statusCode >= 200 && statusCode < 300) {
      _successfulCalls++;
    } else {
      _failedCalls++;
    }
    
    final key = '$method $endpoint';
    _endpointCalls[key] = (_endpointCalls[key] ?? 0) + 1;
    
    final currentAvg = _endpointAvgTimes[key];
    if (currentAvg == null) {
      _endpointAvgTimes[key] = duration;
    } else {
      final count = _endpointCalls[key]!;
      final totalMs = (currentAvg.inMilliseconds * (count - 1)) + duration.inMilliseconds;
      _endpointAvgTimes[key] = Duration(milliseconds: totalMs ~/ count);
    }
    
    if (error != null) {
      _endpointErrors[key] = (_endpointErrors[key] ?? 0) + 1;
    }
    
    if (_totalApiCalls % 10 == 0) {
      printStats();
    }
  }
  
  void printStats() {
    if (!kDebugMode) return;
    
    debugPrint('\n📊 ========== NETWORK STATS ==========');
    debugPrint('📡 Total API Calls: $_totalApiCalls');
    debugPrint('✅ Successful: $_successfulCalls');
    debugPrint('❌ Failed: $_failedCalls');
    debugPrint('=====================================\n');
  }
  
  void reset() {
    _totalApiCalls = 0;
    _successfulCalls = 0;
    _failedCalls = 0;
    _endpointCalls.clear();
    _endpointAvgTimes.clear();
    _endpointErrors.clear();
  }
}
