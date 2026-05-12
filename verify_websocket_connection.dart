import 'dart:async';
import 'dart:convert';


/// Diagnostic tool to verify which WebSocket server you're connected to
/// 
/// Usage:
/// dart run verify_websocket_connection.dart
void main() async {
  print('🔍 WebSocket Connection Diagnostic Tool');
  print('=' * 80);
  
  // Test URLs
  final testUrls = [
    'ws://zg7h02xx-8001.inc1.devtunnels.ms/ws',
    'wss://zg7h02xx-8001.inc1.devtunnels.ms/ws',
    'wss://gruve-api.hardkore.tech/ws',
  ];
  
  for (final url in testUrls) {
    print('\n📡 Testing: $url');
    await testWebSocketConnection(url);
  }
  
  print('\n' + '=' * 80);
  print('✅ Diagnostic complete');
}

Future<void> testWebSocketConnection(String url) async {
  WebSocketChannel? channel;
  StreamSubscription? subscription;
  
  try {
    print('  🔌 Connecting...');
    
    // Create connection with timeout
    final uri = Uri.parse(url);
    channel = WebSocketChannel.connect(uri);
    
    // Set up listener
    final completer = Completer<void>();
    subscription = channel.stream.timeout(
      Duration(seconds: 5),
      onTimeout: (sink) {
        print('  ⏰ Connection timeout');
        completer.complete();
      },
    ).listen(
      (message) {
        print('  📨 Received: $message');
        
        try {
          final data = jsonDecode(message);
          print('  📊 Message type: ${data['type']}');
          
          if (data['type'] == 'connection_established') {
            print('  ✅ Connected to NEW backend (event handler)');
          } else if (data['type'] == 'connected') {
            print('  ⚠️  Connected to OLD backend (requires conversation_id)');
          }
        } catch (e) {
          print('  ⚠️  Non-JSON message: $message');
        }
        
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (error) {
        print('  ❌ Error: $error');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onDone: () {
        print('  🔌 Connection closed');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
    
    // Send heartbeat to test
    print('  💓 Sending heartbeat...');
    final heartbeat = jsonEncode({
      'type': 'heartbeat',
      'action': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    channel.sink.add(heartbeat);
    
    // Wait for response or timeout
    await completer.future;
    
  } catch (e) {
    print('  ❌ Connection failed: $e');
  } finally {
    await subscription?.cancel();
    await channel?.sink.close();
  }
}
