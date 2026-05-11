import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:developer' as developer;

class SocketService {
  // =========================
  // SINGLETON
  // =========================

  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  SocketService._internal();

  // =========================
  // VARIABLES
  // =========================

  WebSocketChannel? _channel;

  StreamSubscription? _socketSubscription;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // =========================
  // STREAM CONTROLLER
  // =========================

  final StreamController<Map<String, dynamic>> messageStream =
      StreamController.broadcast();

  // =========================
  // SOCKET URL
  // =========================

  final String baseUrl = "ws://zg7h02xx-8000.inc1.devtunnels.ms/ws";

  // =========================
  // CONNECT SOCKET
  // =========================

  void connect(String token) {
    final connectionStart = DateTime.now();
    
    try {
      // ALREADY CONNECTED - DUPLICATE PREVENTION
      if (_isConnected) {
        debugPrint(
          "⚠️ [SocketService] ⚠️ SOCKET ALREADY CONNECTED - Duplicate connection prevented",
        );
        debugPrint(
          "🔌 [SocketService] 🔌 Connection status: ALREADY CONNECTED",
        );
        return;
      }

      final socketUrl = "$baseUrl?token=$token";

      debugPrint("🔌 [SocketService] 🔌 CONNECTING SOCKET...");
      debugPrint("🌍 [SocketService] 🌍 SOCKET URL => $socketUrl");
      debugPrint(
        "🎫 [SocketService] 🎫 Token preview: ${token.substring(0, 10)}...",
      );

      // CREATE CONNECTION
      final connectStart = DateTime.now();
      _channel = WebSocketChannel.connect(Uri.parse(socketUrl));
      final connectTime = DateTime.now().difference(connectStart);

      _isConnected = true;
      final totalTime = DateTime.now().difference(connectionStart);

      developer.log('🔌 [PERF] Socket connection: ${connectTime.inMilliseconds}ms, Total: ${totalTime.inMilliseconds}ms', name: 'SocketService');

      debugPrint("✅ [SocketService] ✅ SOCKET CONNECTED SUCCESSFULLY");
      debugPrint("🎉 [SocketService] 🎉 WebSocket connection established");

      // START LISTENING
      _listenMessages();
    } catch (e) {
      _isConnected = false;
      final failedTime = DateTime.now().difference(connectionStart);
      developer.log('🔌 [PERF] Socket connection failed after ${failedTime.inMilliseconds}ms: $e', name: 'SocketService');

      debugPrint("💥 [SocketService] 💥 SOCKET CONNECTION ERROR => $e");
      debugPrint("❌ [SocketService] ❌ Connection failed");
    }
  }

  // =========================
  // LISTEN MESSAGES
  // =========================

  void _listenMessages() {
    try {
      debugPrint("👂 [SocketService] 👂 STARTED SOCKET LISTENER");
      debugPrint("🎧 [SocketService] 🎧 Listening for incoming messages");

      // CANCEL OLD SUBSCRIPTION
      _socketSubscription?.cancel();
      debugPrint("🔄 [SocketService] 🔄 Previous subscription cancelled");

      _socketSubscription = _channel?.stream.listen(
        (event) {
          debugPrint(
            "📩 [SocketService] 📩 RAW SOCKET EVENT RECEIVED => $event",
          );

          try {
            final data = jsonDecode(event);

            debugPrint("✅ [SocketService] ✅ DECODED SOCKET DATA => $data");
            debugPrint("📨 [SocketService] 📨 Forwarding to message stream");

            // SEND TO UI
            messageStream.add(data);
          } catch (e) {
            debugPrint("💥 [SocketService] 💥 JSON DECODE ERROR => $e");
            debugPrint("❌ [SocketService] ❌ Failed to parse message");
          }
        },

        onDone: () {
          debugPrint("🏁 [SocketService] 🏁 SOCKET CONNECTION CLOSED");
          debugPrint("🔌 [SocketService] 🔌 Connection ended by server");
          _isConnected = false;
        },

        onError: (error) {
          debugPrint("💥 [SocketService] 💥 SOCKET STREAM ERROR => $error");
          debugPrint("❌ [SocketService] ❌ Stream error occurred");
          _isConnected = false;
        },
      );
    } catch (e) {
      debugPrint("💥 [SocketService] 💥 LISTENER SETUP ERROR => $e");
      debugPrint("❌ [SocketService] ❌ Failed to start listening");
    }
  }

  // =========================
  // SEND MESSAGE
  // =========================

  void sendMessage({required String conversationId, required String message}) {
    try {
      // CHECK CONNECTION
      if (!_isConnected) {
        debugPrint(
          "❌ [SocketService] ❌ SOCKET NOT CONNECTED - Cannot send message",
        );
        debugPrint("🔌 [SocketService] 🔌 Please establish connection first");
        return;
      }

      // EMPTY MESSAGE CHECK
      if (message.trim().isEmpty) {
        debugPrint("⚠️ [SocketService] ⚠️ EMPTY MESSAGE - Nothing to send");
        debugPrint("📝 [SocketService] 📝 Message content is empty");
        return;
      }

      debugPrint(
        "📝 [SocketService] 📝 Preparing message for conversation: $conversationId",
      );
      debugPrint(
        "💬 [SocketService] 💬 Message content: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}",
      );

      final data = {"conversation_id": conversationId, "content": message};

      final encodedData = jsonEncode(data);

      debugPrint("📤 [SocketService] 📤 SENDING MESSAGE => $encodedData");

      _channel?.sink.add(encodedData);

      debugPrint("✅ [SocketService] ✅ MESSAGE SENT SUCCESSFULLY");
      debugPrint("🎯 [SocketService] 🎯 Message delivered to server");
    } catch (e) {
      debugPrint("💥 [SocketService] 💥 SEND MESSAGE ERROR => $e");
      debugPrint("❌ [SocketService] ❌ Failed to send message");
    }
  }

  // =========================
  // DISCONNECT SOCKET
  // =========================

  void disconnect() {
    try {
      debugPrint("🔌 [SocketService] 🔌 DISCONNECTING SOCKET...");
      debugPrint("👋 [SocketService] 👋 Closing connection");

      _socketSubscription?.cancel();
      debugPrint("🔄 [SocketService] 🔄 Subscription cancelled");

      _channel?.sink.close();
      debugPrint("🔌 [SocketService] 🔌 Channel closed");

      _isConnected = false;

      debugPrint("✅ [SocketService] ✅ SOCKET DISCONNECTED SUCCESSFULLY");
      debugPrint("🏁 [SocketService] 🏁 Connection terminated");
    } catch (e) {
      debugPrint("💥 [SocketService] 💥 DISCONNECT ERROR => $e");
      debugPrint("❌ [SocketService] ❌ Failed to disconnect cleanly");
    }
  }
}
