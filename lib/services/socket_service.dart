import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:gruve_app/core/socket/socket_reconnect_manager.dart';

/// Enhanced SocketService using production-grade reconnect manager
/// Maintains backward compatibility while adding robust features
class SocketService {
  // =========================
  // SINGLETON
  // =========================

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal() {
    _setupEventListeners();
  }

  // =========================
  // RECONNECT MANAGER
  // =========================

  final SocketReconnectManager _reconnectManager = SocketReconnectManager();

  // =========================
  // LEGACY COMPATIBILITY
  // =========================

  bool get isConnected => _reconnectManager.isConnected;
  Stream<Map<String, dynamic>> get messageStream => _reconnectManager.messages;

  // =========================
  // EVENT LISTENERS
  // =========================

  StreamSubscription? _eventSubscription;

  void _setupEventListeners() {
    _eventSubscription = _reconnectManager.events.listen((event) {
      switch (event.type) {
        case SocketEventType.connected:
          _onConnected();
          break;
        case SocketEventType.disconnected:
          _onDisconnected();
          break;
        case SocketEventType.reconnecting:
          _onReconnecting(event.data is int ? event.data as int : 0);
          break;
        case SocketEventType.failed:
          _onFailed();
          break;
        case SocketEventType.error:
          _onError(event.data.toString());
          break;
        case SocketEventType.message:
          // Messages are handled by messageStream
          break;
      }
    });
  }

  void _onConnected() {
    final connectionTime = _reconnectManager.lastConnectedAt;
    debugPrint("✅ [SocketService] ✅ SOCKET CONNECTED SUCCESSFULLY");
    debugPrint("🎉 [SocketService] 🎉 WebSocket connection established");
    if (connectionTime != null) {
      developer.log(
        '🔌 [PERF] Socket connected at: ${connectionTime.toIso8601String()}',
        name: 'SocketService',
      );
    }
  }

  void _onDisconnected() {
    debugPrint("� [SocketService] � SOCKET CONNECTION CLOSED");
    debugPrint(
      "� [SocketService] � Connection ended, will reconnect automatically",
    );
  }

  void _onReconnecting(int attempt) {
    debugPrint("� [SocketService] � RECONNECTING ATTEMPT $attempt");
    debugPrint("⏳ [SocketService] ⏳ Attempting to restore connection...");
  }

  void _onFailed() {
    debugPrint("❌ [SocketService] ❌ CONNECTION FAILED");
    debugPrint("� [SocketService] � Max reconnect attempts reached");
  }

  void _onError(String error) {
    debugPrint("💥 [SocketService] 💥 SOCKET ERROR => $error");
    debugPrint("❌ [SocketService] ❌ Connection error occurred");
  }

  // =========================
  // PUBLIC METHODS
  // =========================

  /// Connect to WebSocket (maintains backward compatibility)
  Future<void> connect(String token) async {
    debugPrint("🔌 [SocketService] 🔌 CONNECTING SOCKET...");
    final previewLength = token.length < 10 ? token.length : 10;
    debugPrint(
      "🎫 [SocketService] 🎫 Token preview: ${token.substring(0, previewLength)}...",
    );

    // The reconnect manager will handle token internally
    await _reconnectManager.connect();
  }

  /// Send message through enhanced socket with timeout protection
  /// Returns true if message was successfully queued, false otherwise
  bool sendMessage({
    required String conversationId, 
    required String message,
    String? senderId,
    Map<String, dynamic>? additionalData,
  }) {
    if (message.trim().isEmpty) {
      debugPrint("⚠️ [SocketService] ⚠️ EMPTY MESSAGE - Nothing to send");
      return false;
    }

    if (!_reconnectManager.isConnected) {
      debugPrint(
        "⚠️ [SocketService] ⚠️ WEBSOCKET NOT CONNECTED - Message not sent",
      );
      return false;
    }

    debugPrint(
      "📝 [SocketService] 📝 Sending to conversation: $conversationId",
    );
    debugPrint(
      "💬 [SocketService] 💬 Message: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}",
    );

    // 🚨 PRODUCTION FIX: Use correct event structure for backend
    final messageData = {
      'type': 'send_message', // ✅ Correct event type
      'conversation_id': conversationId, // ✅ Required: UUID string
      'content': message, // ✅ Required: message content
      'sender_id': senderId ?? 'current_user', // ✅ Required: sender ID
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?additionalData,
    };

    try {
      debugPrint("🚀 [SocketService] 🚀 Attempting to send via WebSocket...");
      final sent = _reconnectManager.sendMessage(messageData);

      if (sent) {
        debugPrint("✅ [SocketService] ✅ MESSAGE QUEUED FOR DELIVERY");
      } else {
        debugPrint("❌ [SocketService] ❌ MESSAGE NOT QUEUED");
      }
      
      return sent;
    } catch (e) {
      debugPrint("❌ [SocketService] ❌ FAILED TO SEND MESSAGE: $e");
      return false;
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    debugPrint("🔌 [SocketService] 🔌 DISCONNECTING SOCKET...");
    debugPrint("👋 [SocketService] 👋 Closing connection");

    await _reconnectManager.disconnect();

    debugPrint("✅ [SocketService] ✅ SOCKET DISCONNECTED SUCCESSFULLY");
  }

  /// Reset connection (useful for token changes)
  Future<void> reset() async {
    debugPrint("🔄 [SocketService] 🔄 RESETTING CONNECTION");
    await _reconnectManager.reset();
  }

  // =========================
  // ENHANCED FEATURES
  // =========================

  /// Get current connection state
  SocketState get state => _reconnectManager.state;

  /// Get reconnect attempts count
  int get reconnectAttempts => _reconnectManager.reconnectAttempts;

  /// Check if currently reconnecting
  bool get isReconnecting => _reconnectManager.isConnecting;

  /// Listen to socket events for advanced UI handling
  Stream<SocketEvent> get events => _reconnectManager.events;

  // =========================
  // DISPOSE
  // =========================

  Future<void> dispose() async {
    debugPrint("🗑️ [SocketService] 🗑️ DISPOSING SOCKET SERVICE");

    await _eventSubscription?.cancel();
    _eventSubscription = null;

    await _reconnectManager.dispose();

    debugPrint("✅ [SocketService] ✅ SOCKET SERVICE DISPOSED");
  }
}
