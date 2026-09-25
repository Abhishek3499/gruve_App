import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';
import 'package:gruve_app/core/socket/socket_logger.dart';
import 'package:gruve_app/core/socket/socket_reconnect_manager.dart';

/// SocketService
/// Provides high-level real-time messaging, online presence tracking, and event broadcasting.
class SocketService {
  // Singleton instance
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal() {
    _setupEventListeners();
  }

  final SocketReconnectManager _reconnectManager = SocketReconnectManager();
  StreamSubscription? _eventSubscription;

  /// Reactive set of online user IDs
  final ValueNotifier<Set<String>> onlineUsers = ValueNotifier<Set<String>>({});

  // ==========================================
  // Public Getters & Streams
  // ==========================================

  bool get isConnected => _reconnectManager.isConnected;
  SocketState get state => _reconnectManager.state;
  Stream<Map<String, dynamic>> get messageStream => _reconnectManager.messages;
  Stream<SocketEvent> get events => _reconnectManager.events;

  // ==========================================
  // Connection Actions
  // ==========================================

  /// Connects WebSocket (loads token automatically or uses optional passed token)
  Future<void> connect([String? token]) async {
    await _reconnectManager.connect();
  }

  /// Cleanly disconnects from WebSocket
  Future<void> disconnect() async {
    await _reconnectManager.disconnect();
    _setOnlineUsers(<String>{});
  }

  /// Sets whether the socket is allowed to auto-reconnect (true when logged in, false on logout)
  void setAuthState(bool authenticated) {
    _reconnectManager.setAuthState(authenticated);
  }

  /// Reconnects with fresh token after a token refresh
  Future<void> reconnectWithLatestTokenIfActive() async {
    if (_reconnectManager.isConnected) {
      await _reconnectManager.disconnect();
      await _reconnectManager.connect();
    }
  }

  // ==========================================
  // Messaging & Events
  // ==========================================

  /// Sends a chat message via WebSocket
  bool sendMessage({
    required String conversationId,
    String? content,
    String? replyToMessageId,
    Map<String, dynamic>? media,
    String? senderId,
    Map<String, dynamic>? additionalData,
  }) {
    final trimmedContent = content?.trim() ?? '';
    if (trimmedContent.isEmpty && media == null) return false;

    if (!isConnected) {
      SocketLogger.error('Cannot send message - disconnected');
      return false;
    }

    final messageData = <String, dynamic>{
      'type': 'chat.send',
      'conversation_id': conversationId,
      if (trimmedContent.isNotEmpty) 'content': trimmedContent,
      if (replyToMessageId != null && replyToMessageId.isNotEmpty)
        'reply_to_message_id': replyToMessageId,
      if (media != null) 'media': media,
      if (senderId != null && senderId.isNotEmpty) 'sender_id': senderId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?additionalData,
    };

    final sent = _reconnectManager.send(messageData);
    if (sent) {
      unawaited(CacheInvalidationService().onMessageSent(conversationId));
    }
    return sent;
  }


  // react to a message with an emoji

  bool sendMessageReaction({
  required String conversationId,
  required String messageId,
  required String emoji,
}) {
  if (!isConnected) {
    SocketLogger.error(
      'Cannot send message reaction - disconnected',
    );
    return false;
  }

  final reactionData = <String, dynamic>{
    'type': 'message.react',
    'conversation_id': conversationId,
    'message_id': messageId,
    'emoji': emoji,
  };

  return _reconnectManager.send(reactionData);
}

  /// Sends a raw event map (e.g. typing indicator, read receipt)
  bool sendEvent(Map<String, dynamic> eventData) {
    if (!isConnected) return false;
    return _reconnectManager.send(eventData);
  }

  // ==========================================
  // Presence & Event Handling
  // ==========================================

  void _setupEventListeners() {
    _eventSubscription = _reconnectManager.events.listen((event) {
      switch (event.type) {
        case SocketEventType.connected:
          break;
        case SocketEventType.disconnected:
        case SocketEventType.failed:
          _setOnlineUsers(<String>{});
          break;
        case SocketEventType.message:
          if (event.data is Map<String, dynamic>) {
            _handlePresenceEvent(event.data as Map<String, dynamic>);
          }
          break;
        default:
          break;
      }
    });
  }

  void _handlePresenceEvent(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    if (type == 'online_users' || type == 'presence_snapshot') {
      final userList =
          data['users'] ??
          data['online_users'] ??
          (data['data'] is Map ? data['data']['users'] : null);
      if (userList is List) {
        final onlineIds = <String>{};
        for (final item in userList) {
          final id = item is Map
              ? (item['user_id'] ?? item['id'] ?? '').toString()
              : item.toString();
          if (id.isNotEmpty) onlineIds.add(id);
        }
        _setOnlineUsers(onlineIds);
      }
    } else if (type == 'user_online' || type == 'presence_online') {
      final userId = (data['user_id'] ?? data['userId'] ?? '').toString();
      if (userId.isNotEmpty) {
        final updated = Set<String>.from(onlineUsers.value)..add(userId);
        _setOnlineUsers(updated);
      }
    } else if (type == 'user_offline' || type == 'presence_offline') {
      final userId = (data['user_id'] ?? data['userId'] ?? '').toString();
      if (userId.isNotEmpty) {
        final updated = Set<String>.from(onlineUsers.value)..remove(userId);
        _setOnlineUsers(updated);
      }
    }
  }

  void _setOnlineUsers(Set<String> users) {
    onlineUsers.value = users
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await disconnect();
  }
}
