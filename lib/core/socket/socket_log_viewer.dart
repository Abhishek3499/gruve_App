import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'socket_logger.dart';
import 'socket_test_utility.dart';

/// Socket Log Viewer Widget
/// 
/// A simple UI to view and export socket logs in real-time
class SocketLogViewer extends StatefulWidget {
  const SocketLogViewer({super.key});

  @override
  State<SocketLogViewer> createState() => _SocketLogViewerState();
}

class _SocketLogViewerState extends State<SocketLogViewer> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _displayLogs = [];
  bool _autoScroll = true;
  bool _isCapturing = false;
  
  @override
  void initState() {
    super.initState();
    _refreshLogs();
    _startLogCapture();
  }
  
  void _refreshLogs() {
    setState(() {
      _displayLogs.clear();
      _displayLogs.addAll(SocketLogger.getLogs());
    });
    
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }
  
  void _startLogCapture() {
    if (!_isCapturing) {
      _isCapturing = true;
      SocketLogger.startCapture();
      
      // Auto-refresh logs every 2 seconds
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        _refreshLogs();
      });
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _clearLogs() {
    SocketLogger.clearLogs();
    _refreshLogs();
  }
  
  void _exportLogs() async {
    try {
      final logs = SocketLogger.getLogs();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('socket_logs_export_$timestamp.txt');
      
      final content = logs.join('\n\n');
      await file.writeAsString(content);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logs exported to ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _runSocketTest() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Running socket test...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    await SocketTestUtility.startTest();
    _refreshLogs();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Socket test completed!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Color _getLogColor(String log) {
    if (log.contains('ERROR') || log.contains('❌')) {
      return Colors.red;
    } else if (log.contains('WARNING') || log.contains('⚠️')) {
      return Colors.orange;
    } else if (log.contains('SUCCESS') || log.contains('✅')) {
      return Colors.green;
    } else if (log.contains('DEBUG')) {
      return Colors.blue;
    } else if (log.contains('HEARTBEAT')) {
      return Colors.purple;
    } else if (log.contains('OUTGOING')) {
      return Colors.teal;
    } else if (log.contains('INCOMING')) {
      return Colors.indigo;
    }
    return Colors.white;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Socket Logs', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C0B21),
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.auto_scroll : Icons.stop_screen_share),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
            tooltip: 'Refresh logs',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
            tooltip: 'Export logs',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _runSocketTest,
            tooltip: 'Run socket test',
          ),
        ],
      ),
      body: Column(
        children: [
          // Log summary
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A1F2E),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Logs: ${_displayLogs.length} | Auto-scroll: ${_autoScroll ? "ON" : "OFF"}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Log display
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _displayLogs.length,
                itemBuilder: (context, index) {
                  final log = _displayLogs[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: SelectableText(
                      log,
                      style: TextStyle(
                        color: _getLogColor(log),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Quick actions
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A1F2E),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runSocketTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF72008D),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportLogs,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42174C),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// Quick log viewer dialog
class QuickLogViewer extends StatelessWidget {
  const QuickLogViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C0B21),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Socket Logs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: SocketLogger.getLogs().length,
                  itemBuilder: (context, index) {
                    final log = SocketLogger.getLogs()[index];
                    return SelectableText(
                      log,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      SocketLogger.clearLogs();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      SocketLogger.printSummary();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Summary'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Utility functions for quick access
class SocketLogUtils {
  /// Show quick log viewer
  static void showQuickViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const QuickLogViewer(),
    );
  }
  
  /// Show full log viewer
  static void showFullViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SocketLogViewer(),
      ),
    );
  }
  
  /// Get log summary as string
  static String getLogSummary() {
    final logs = SocketLogger.getLogs();
    final outgoingCount = logs.where((log) => log.contains('OUTGOING')).length;
    final incomingCount = logs.where((log) => log.contains('INCOMING')).length;
    final errorCount = logs.where((log) => log.contains('ERROR')).length;
    final heartbeatCount = logs.where((log) => log.contains('HEARTBEAT')).length;
    
    return '''
Socket Log Summary:
📤 Outgoing messages: $outgoingCount
📥 Incoming messages: $incomingCount
💥 Errors: $errorCount
💓 Heartbeats: $heartbeatCount
📊 Total events: ${logs.length}
    ''';
  }
  
  /// Copy logs to clipboard
  static Future<void> copyLogsToClipboard() async {
    try {
      final logs = SocketLogger.getLogs().join('\n\n');
      await Clipboard.setData(ClipboardData(text: logs));
    } catch (e) {
      print('Failed to copy logs to clipboard: $e');
    }
  }
}
