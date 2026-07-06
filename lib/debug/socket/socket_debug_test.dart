import 'package:flutter/material.dart';
import 'package:gruve_app/core/socket/socket_logger.dart';
import 'socket_log_viewer.dart';

/// Simple debug test widget to verify socket logging
class SocketDebugTest extends StatefulWidget {
  const SocketDebugTest({super.key});

  @override
  State<SocketDebugTest> createState() => _SocketDebugTestState();
}

class _SocketDebugTestState extends State<SocketDebugTest> {
  String _testResult = 'No test run yet';
  bool _isTestRunning = false;

  @override
  void initState() {
    super.initState();
    // Start logging automatically
    SocketLogger.startCapture();
  }

  Future<void> _runQuickTest() async {
    if (_isTestRunning) return;
    
    setState(() {
      _isTestRunning = true;
      _testResult = 'Running test...';
    });

    try {
      // Test basic logging
      SocketLogger.logEvent('TEST', 'Quick debug test started');
      
      // Test heartbeat logging
      SocketLogger.logHeartbeat('ping', success: true, responseTime: 45);
      
      // Test message logging
      SocketLogger.logOutgoing({
        'type': 'send_message',
        'conversation_id': 'test-123',
        'content': 'Test message',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, true);
      
      SocketLogger.logIncoming('{"type":"message","content":"Test response"}', {
        'type': 'message',
        'content': 'Test response',
      });
      
      // Test connection state logging
      SocketLogger.logConnectionState('disconnected', 'connected', data: {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Test error logging
      SocketLogger.logError('Test error', context: 'debug_test', data: {
        'test': true,
        'error_code': 'TEST_ERROR',
      });
      
      // Get summary
      final summary = SocketLogger.getLogs();
      
      setState(() {
        _testResult = 'Test completed! ${summary.length} events logged.';
      });
      
    } catch (e) {
      setState(() {
        _testResult = 'Test failed: $e';
      });
    } finally {
      setState(() {
        _isTestRunning = false;
      });
    }
  }

  void _showLogs() {
    SocketLogUtils.showQuickViewer(context);
  }

  void _showFullViewer() {
    SocketLogUtils.showFullViewer(context);
  }

  void _printSummary() {
    SocketLogger.printSummary();
    setState(() {
      _testResult = 'Summary printed to console';
    });
  }

  void _clearLogs() {
    SocketLogger.clearLogs();
    setState(() {
      _testResult = 'Logs cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C0B21),
      appBar: AppBar(
        title: const Text('Socket Debug Test', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF42174C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test result
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1F2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResult,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test buttons
            ElevatedButton.icon(
              onPressed: _isTestRunning ? null : _runQuickTest,
              icon: _isTestRunning 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.play_arrow),
              label: Text(_isTestRunning ? 'Running...' : 'Run Quick Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF72008D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _showLogs,
              icon: const Icon(Icons.visibility),
              label: const Text('Show Quick Logs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42174C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _showFullViewer,
              icon: const Icon(Icons.fullscreen),
              label: const Text('Full Log Viewer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A1F2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _printSummary,
              icon: const Icon(Icons.analytics),
              label: const Text('Print Summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C0B21),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _clearLogs,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Logs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1F2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Heartbeat format: {"type":"heartbeat","action":"ping"}\n'
                    '• All socket events are logged\n'
                    '• Check console for real-time logs\n'
                    '• Use full viewer for detailed analysis',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
