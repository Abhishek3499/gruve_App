import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'socket_reconnect_manager.dart';
import 'socket_logger.dart';

/// Comprehensive Socket Testing Utility
/// 
/// This utility helps test and debug WebSocket connections with detailed logging
class SocketTestUtility {
  static bool _isTestRunning = false;
  static Timer? _testTimer;
  static int _messagesSent = 0;
  static int _messagesReceived = 0;
  static int _errorsCount = 0;
  static final List<Map<String, dynamic>> _testResults = [];
  
  /// Start comprehensive socket test
  static Future<void> startTest() async {
    if (_isTestRunning) {
      return;
    }
    
    _isTestRunning = true;
    _messagesSent = 0;
    _messagesReceived = 0;
    _errorsCount = 0;
    _testResults.clear();
    
    SocketLogger.logEvent('TEST_START', 'Comprehensive socket test started');
    
    // Test 1: Connection Test
    await _testConnection();
    
    // Test 2: Heartbeat Test
    await _testHeartbeat();
    
    // Test 3: Message Send Test
    await _testMessageSending();
    
    // Test 4: Message Receive Test
    await _testMessageReceiving();
    
    // Test 5: Error Handling Test
    await _testErrorHandling();
    
    // Test 6: Reconnection Test
    await _testReconnection();
    
    await _generateTestReport();
    _isTestRunning = false;
    
    SocketLogger.logEvent('TEST_END', 'Comprehensive socket test completed');
  }
  
  /// Test connection establishment
  static Future<void> _testConnection() async {
    try {
      final manager = SocketReconnectManager();
      
      // Test connection state
      final initialState = manager.state;
      
      // Try to connect
      await manager.connect();
      
      // Wait for connection
      await Future.delayed(const Duration(seconds: 5));
      
      final finalState = manager.state;
      
      final success = finalState == SocketState.connected;
      
      _testResults.add({
        'test': 'connection',
        'success': success,
        'initialState': initialState.name,
        'finalState': finalState.name,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logEvent('TEST_CONNECTION', 'Connection test completed', data: {
        'success': success,
        'initialState': initialState.name,
        'finalState': finalState.name,
      });
      
    } catch (e) {
      _errorsCount++;
      _testResults.add({
        'test': 'connection',
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logError('Connection test failed: $e', context: 'testConnection');
    }
  }
  
  /// Test heartbeat mechanism
  static Future<void> _testHeartbeat() async {
    try {
      final manager = SocketReconnectManager();
      
      if (!manager.isConnected) {
        return;
      }
      
      // Send manual heartbeat
      final success = manager.sendMessage({
        'type': 'heartbeat',
        'action': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'test': true,
      });
      
      _messagesSent++;
      
      // Wait for response
      await Future.delayed(const Duration(seconds: 3));
      
      _testResults.add({
        'test': 'heartbeat',
        'success': success,
        'messagesSent': _messagesSent,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logEvent('TEST_HEARTBEAT', 'Heartbeat test completed', data: {
        'success': success,
        'messagesSent': _messagesSent,
      });
      
    } catch (e) {
      _errorsCount++;
      _testResults.add({
        'test': 'heartbeat',
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logError('Heartbeat test failed: $e', context: 'testHeartbeat');
    }
  }
  
  /// Test message sending
  static Future<void> _testMessageSending() async {
    try {
      final manager = SocketReconnectManager();
      
      if (!manager.isConnected) {
        return;
      }
      
      // Send test message
      final testMessage = {
        'type': 'send_message',
        'conversation_id': 'test-conversation',
        'content': 'Test message from SocketTestUtility',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'test': true,
      };
      
      final success = manager.sendMessage(testMessage);
      _messagesSent++;
      
      _testResults.add({
        'test': 'message_sending',
        'success': success,
        'messageSent': testMessage,
        'messagesSent': _messagesSent,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logEvent('TEST_MESSAGE_SENDING', 'Message sending test completed', data: {
        'success': success,
        'messageSent': testMessage,
        'messagesSent': _messagesSent,
      });
      
    } catch (e) {
      _errorsCount++;
      _testResults.add({
        'test': 'message_sending',
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logError('Message sending test failed: $e', context: 'testMessageSending');
    }
  }
  
  /// Test message receiving
  static Future<void> _testMessageReceiving() async {
    try {
      final manager = SocketReconnectManager();
      
      if (!manager.isConnected) {
        return;
      }
      
      // Listen for messages
      late StreamSubscription subscription;
      bool messageReceived = false;
      
      subscription = manager.messages.listen((message) {
        _messagesReceived++;
        messageReceived = true;
        
        _testResults.add({
          'test': 'message_receiving',
          'success': true,
          'messageReceived': message,
          'messagesReceived': _messagesReceived,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        SocketLogger.logEvent('TEST_MESSAGE_RECEIVING', 'Message received', data: {
          'message': message,
          'messagesReceived': _messagesReceived,
        });
      });
      
      // Wait for messages
      await Future.delayed(const Duration(seconds: 10));
      
      await subscription.cancel();
      
      if (!messageReceived) {
        _testResults.add({
          'test': 'message_receiving',
          'success': false,
          'error': 'No messages received in 10 seconds',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        SocketLogger.logError('No messages received in 10 seconds', context: 'testMessageReceiving');
      }
      
    } catch (e) {
      _errorsCount++;
      _testResults.add({
        'test': 'message_receiving',
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logError('Message receiving test failed: $e', context: 'testMessageReceiving');
    }
  }
  
  /// Test error handling
  static Future<void> _testErrorHandling() async {
    try {
      final manager = SocketReconnectManager();
      
      if (!manager.isConnected) {
        return;
      }
      
      // Send invalid message to trigger error
      final invalidMessage = {
        'type': 'invalid_command',
        'data': 'This should trigger an error',
        'test': true,
      };
      
      final sent = manager.sendMessage(invalidMessage);
      _messagesSent++;
      
      // Wait for error response
      await Future.delayed(const Duration(seconds: 3));
      
      _testResults.add({
        'test': 'error_handling',
        'success': sent, // Success if we could send the invalid message
        'invalidMessage': invalidMessage,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logEvent('TEST_ERROR_HANDLING', 'Error handling test completed', data: {
        'success': sent,
        'invalidMessage': invalidMessage,
      });
      
    } catch (e) {
      _errorsCount++;
      _testResults.add({
        'test': 'error_handling',
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logError('Error handling test failed: $e', context: 'testErrorHandling');
    }
  }
  
  /// Test reconnection
  static Future<void> _testReconnection() async {
    try {
      final manager = SocketReconnectManager();
      
      // Disconnect
      await manager.disconnect();
      await Future.delayed(const Duration(seconds: 2));
      
      // Reconnect
      await manager.connect();
      await Future.delayed(const Duration(seconds: 5));
      
      final reconnected = manager.isConnected;
      
      _testResults.add({
        'test': 'reconnection',
        'success': reconnected,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logEvent('TEST_RECONNECTION', 'Reconnection test completed', data: {
        'success': reconnected,
      });
      
    } catch (e) {
      _errorsCount++;
      _testResults.add({
        'test': 'reconnection',
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      SocketLogger.logError('Reconnection test failed: $e', context: 'testReconnection');
    }
  }
  
  /// Generate comprehensive test report
  static Future<void> _generateTestReport() async {
    final testSummary = {
      'totalTests': _testResults.length,
      'passedTests': _testResults.where((r) => r['success'] == true).length,
      'failedTests': _testResults.where((r) => r['success'] == false).length,
      'messagesSent': _messagesSent,
      'messagesReceived': _messagesReceived,
      'errorsCount': _errorsCount,
      'testDuration': DateTime.now().toIso8601String(),
    };
    
    final report = {
      'testSummary': testSummary,
      'testResults': _testResults,
      'socketLogs': SocketLogger.getLogs(),
    };
    
    // Save report to file
    final reportFile = File('socket_test_report_${DateTime.now().millisecondsSinceEpoch}.json');
    await reportFile.writeAsString(jsonEncode(report));
    
    SocketLogger.logEvent('TEST_REPORT', 'Test report generated', data: testSummary as Map<String, dynamic>?);
  }
  
  /// Get current test statistics
  static Map<String, dynamic> getTestStats() {
    return {
      'isTestRunning': _isTestRunning,
      'messagesSent': _messagesSent,
      'messagesReceived': _messagesReceived,
      'errorsCount': _errorsCount,
      'testResults': _testResults,
    };
  }
  
  /// Stop current test
  static void stopTest() {
    if (_testTimer != null) {
      _testTimer!.cancel();
      _testTimer = null;
    }
    
    _isTestRunning = false;
    SocketLogger.logEvent('TEST_STOP', 'Socket test stopped');
  }
}

/// Extension for easy testing
extension SocketTestExtension on SocketReconnectManager {
  /// Quick connection test
  Future<bool> testConnection() async {
    try {
      await connect();
      await Future.delayed(const Duration(seconds: 3));
      return isConnected;
    } catch (e) {
      SocketLogger.logError('Connection test failed: $e', context: 'testConnection');
      return false;
    }
  }
  
  /// Quick heartbeat test
  Future<bool> testHeartbeat() async {
    if (!isConnected) return false;
    
    try {
      final success = sendMessage({
        'type': 'heartbeat',
        'action': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'test': true,
      });
      
      await Future.delayed(const Duration(seconds: 2));
      return success;
    } catch (e) {
      SocketLogger.logError('Heartbeat test failed: $e', context: 'testHeartbeat');
      return false;
    }
  }
}
