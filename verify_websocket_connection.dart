import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';


/// Diagnostic tool to verify which WebSocket server you're connected to
/// 
/// Usage:
/// dart run verify_websocket_connection.dart
void main() async {
  developer.log('🔍 WebSocket Connection Diagnostic Tool');
  developer.log('=' * 80);
  
  // Test URLs
  final testUrls = [
    'ws://zg7h02xx-8001.inc1.devtunnels.ms/ws',
    'wss://zg7h02xx-8001.inc1.devtunnels.ms/ws',
    'wss://gruve-api.hardkore.tech/ws',
  ];
  
  for (final url in testUrls) {
    developer.log('\n📡 Testing: $url');
    await testWebSocketConnection(url);
  }
  
  developer.log('\n${'=' * 80}');
  developer.log('✅ Diagnostic complete');
}

Future<void> testWebSocketConnection(String url) async {
  WebSocketChannel? channel;
  StreamSubscription? subscription;
  
  try {
    developer.log('  🔌 Connecting...');
    
    // Create connection with timeout
    final uri = Uri.parse(url);
    channel = WebSocketChannel.connect(uri);
    
    // Set up listener
    final completer = Completer<void>();
    subscription = channel.stream.timeout(
      Duration(seconds: 5),
      onTimeout: (sink) {
        developer.log('  ⏰ Connection timeout');
        completer.complete();
      },
    ).listen(
      (message) {
        developer.log('  📨 Received: $message');
        
        try {
          final data = jsonDecode(message);
          developer.log('  📊 Message type: ${data['type']}');
          
          if (data['type'] == 'connection_established') {
            developer.log('  ✅ Connected to NEW backend (event handler)');
          } else if (data['type'] == 'connected') {
            developer.log('  ⚠️  Connected to OLD backend (requires conversation_id)');
          }
        } catch (e) {
          developer.log('  ⚠️  Non-JSON message: $message');
        }
        
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (error) {
        developer.log('  ❌ Error: $error');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onDone: () {
        developer.log('  🔌 Connection closed');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
    
    // Send heartbeat to test
    developer.log('  💓 Sending heartbeat...');
    final heartbeat = jsonEncode({
      'type': 'heartbeat',
      'action': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    channel.sink.add(heartbeat);
    
    // Wait for response or timeout
    await completer.future;
    
  } catch (e) {
    developer.log('  ❌ Connection failed: $e');
  } finally {
    await subscription?.cancel();
    await channel?.sink.close();
  }
}
