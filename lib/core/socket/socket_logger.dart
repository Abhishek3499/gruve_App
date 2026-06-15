import 'dart:io';
import 'dart:convert';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Comprehensive Socket Logging Utility
/// 
/// Usage:
/// 1. Call SocketLogger.startCapture() to begin logging
/// 2. Call SocketLogger.stopCapture() to stop and save logs
/// 3. Check socket_logs.txt file for complete log history
class SocketLogger {
  static bool _isCapturing = false;
  static final List<String> _logs = [];
  static late File _logFile;
  
  /// Start capturing socket logs
  static void startCapture() {
    if (_isCapturing) return;
    
    _isCapturing = true;
    _logs.clear();
    _initializeLogFile();
    
    AppLogger.d('🔌 [SOCKET LOGGER] Started capturing socket logs');
    logEvent('LOGGER_START', 'Socket logging session started');
  }
  
  /// Stop capturing and save logs to file
  static Future<void> stopCapture() async {
    if (!_isCapturing) return;
    
    _isCapturing = false;
    await _saveLogsToFile();
    
    AppLogger.d('🔌 [SOCKET LOGGER] Stopped capturing. Logs saved to socket_logs.txt');
    logEvent('LOGGER_STOP', 'Socket logging session stopped');
  }
  
  /// Log a socket event
  static void logEvent(String type, String message, {Map<String, dynamic>? data}) {
    if (!_isCapturing) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $type: $message';
    
    if (data != null) {
      final dataJson = jsonEncode(data);
      _logs.add('$logEntry\nData: $dataJson\n');
    } else {
      _logs.add(logEntry);
    }
    
    // Also print to console for immediate visibility
    AppLogger.d('🔌 [SOCKET LOG] $logEntry');
    if (data != null) {
      AppLogger.d('📊 [SOCKET DATA] $data');
    }
  }
  
  /// Log outgoing message
  static void logOutgoing(Map<String, dynamic> message, bool success) {
    logEvent('OUTGOING', 'Message sent', data: {
      'success': success,
      'type': message['type'],
      'action': message['action'],
      'conversationId': message['conversation_id'],
      'messageId': message['id'],
      'timestamp': message['timestamp'],
      'fullMessage': message,
    });
  }
  
  /// Log incoming message
  static void logIncoming(dynamic rawMessage, Map<String, dynamic>? decodedMessage) {
    logEvent('INCOMING', 'Message received', data: {
      'rawMessage': rawMessage.toString(),
      'decodedMessage': decodedMessage,
      'type': decodedMessage?['type'],
      'action': decodedMessage?['action'],
      'conversationId': decodedMessage?['conversation_id'],
      'messageId': decodedMessage?['id'],
    });
  }
  
  /// Log connection state change
  static void logConnectionState(String fromState, String toState, {String? reason, Map<String, dynamic>? data}) {
    logEvent('CONNECTION_STATE', 'State changed', data: {
      'from': fromState,
      'to': toState,
      'reason': reason,
      ...?data,
    });
  }
  
  /// Log heartbeat
  static void logHeartbeat(String action, {bool? success, int? responseTime}) {
    logEvent('HEARTBEAT', 'Heartbeat $action', data: {
      'action': action,
      'success': success,
      'responseTime': responseTime,
    });
  }
  
  /// Log error
  static void logError(String error, {String? context, Map<String, dynamic>? data}) {
    logEvent('ERROR', error, data: {
      'context': context,
      'data': data,
    });
  }
  
  /// Get all captured logs
  static List<String> getLogs() {
    return List.unmodifiable(_logs);
  }
  
  /// Clear all logs
  static void clearLogs() {
    _logs.clear();
    AppLogger.d('🔌 [SOCKET LOGGER] Logs cleared');
  }
  
  /// Print summary of captured events
  static void printSummary() {
    if (_logs.isEmpty) {
      AppLogger.d('🔌 [SOCKET LOGGER] No logs captured');
      return;
    }
    
    final outgoingCount = _logs.where((log) => log.contains('OUTGOING')).length;
    final incomingCount = _logs.where((log) => log.contains('INCOMING')).length;
    final errorCount = _logs.where((log) => log.contains('ERROR')).length;
    final heartbeatCount = _logs.where((log) => log.contains('HEARTBEAT')).length;
    
    AppLogger.d('🔌 [SOCKET LOGGER SUMMARY]');
    AppLogger.d('📤 Outgoing messages: $outgoingCount');
    AppLogger.d('📥 Incoming messages: $incomingCount');
    AppLogger.d('💥 Errors: $errorCount');
    AppLogger.d('💓 Heartbeats: $heartbeatCount');
    AppLogger.d('📊 Total events: ${_logs.length}');
  }
  
  static void _initializeLogFile() {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    _logFile = File('socket_logs_$currentTime.txt');
  }
  
  static Future<void> _saveLogsToFile() async {
    try {
      final content = _logs.join('\n\n');
      await _logFile.writeAsString(content);
      AppLogger.d('🔌 [SOCKET LOGGER] Logs saved to ${_logFile.path}');
    } catch (e) {
      AppLogger.d('❌ [SOCKET LOGGER] Failed to save logs: $e');
    }
  }
}

/// Extension methods for easy logging
extension SocketLoggerExt on SocketLogger {
  /// Quick log for debugging
  static void debug(String message) {
    SocketLogger.logEvent('DEBUG', message);
  }
  
  /// Quick log for info
  static void info(String message) {
    SocketLogger.logEvent('INFO', message);
  }
  
  /// Quick log for warning
  static void warning(String message) {
    SocketLogger.logEvent('WARNING', message);
  }
}
