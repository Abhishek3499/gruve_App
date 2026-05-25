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
  // ONLINE USERS
  // =========================

  final ValueNotifier<Set<String>> onlineUsers = ValueNotifier({});
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
          if (event.data != null && event.data is Map<String, dynamic>) {
            _handleSocketMessage(event.data as Map<String, dynamic>);
          }

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
    _setOnlineUsers(<String>{});
    debugPrint("[SocketService] SOCKET CONNECTION CLOSED");
    debugPrint(
      "[SocketService] Connection ended, will reconnect automatically",
    );
  }

  void _onReconnecting(int attempt) {
    debugPrint("[SocketService] RECONNECTING ATTEMPT $attempt");
    debugPrint("⏳ [SocketService] ⏳ Attempting to restore connection...");
  }

  void _onFailed() {
    _setOnlineUsers(<String>{});
    debugPrint("❌ [SocketService] ❌ CONNECTION FAILED");
    debugPrint("[SocketService] Max reconnect attempts reached");
  }

  void _onError(String error) {
    debugPrint("💥 [SocketService] 💥 SOCKET ERROR => $error");
    debugPrint("❌ [SocketService] ❌ Connection error occurred");
  }

  // ADD HERE 👇👇👇

  void _handleSocketMessage(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    debugPrint("📩 [SocketService] Message Type => $type");

    switch (type) {
      case 'connected':
      case 'presence_snapshot':
      case 'online_users':
        final updatedUsers = <String>{};

        final users = _extractUsersList(data);

        if (users != null) {
          for (final user in users) {
            final userId = _extractUserId(user);
            if (userId.isEmpty) continue;

            final isOnline = user is Map
                ? _extractOnlineFlag(Map<String, dynamic>.from(user))
                : true;

            if (isOnline) {
              updatedUsers.add(userId);
            }
          }
        }

        _setOnlineUsers(updatedUsers);

        debugPrint("🟢 ONLINE USERS => ${onlineUsers.value}");

        break;
      case 'user_online':
      case 'presence_online':
      case 'user_connected':
      case 'user_active':
        final userId = _extractUserId(data);

        if (userId.isNotEmpty) {
          final updatedUsers = Set<String>.from(onlineUsers.value);

          updatedUsers.add(userId);

          _setOnlineUsers(updatedUsers);

          debugPrint("🟢 USER ONLINE => $userId");
        }

        break;

      case 'user_offline':
      case 'presence_offline':
      case 'user_disconnected':
      case 'user_inactive':
        final userId = _extractUserId(data);

        if (userId.isNotEmpty) {
          final updatedUsers = Set<String>.from(onlineUsers.value);

          updatedUsers.remove(userId);

          _setOnlineUsers(updatedUsers);

          debugPrint("🔴 USER OFFLINE => $userId");
        }

        break;

      case 'presence_update':
      case 'user_presence':
      case 'user_status':
      case 'status_update':
      case 'user_status_changed':
        final userId = _extractUserId(data);

        if (userId.isNotEmpty) {
          final updatedUsers = Set<String>.from(onlineUsers.value);
          if (_extractOnlineFlag(data)) {
            updatedUsers.add(userId);
          } else {
            updatedUsers.remove(userId);
          }
          _setOnlineUsers(updatedUsers);
          debugPrint(
            "USER PRESENCE => $userId online=${onlineUsers.value.contains(userId)}",
          );
        }
        break;

      default:
        _applyGenericPresenceUpdate(data);
    }
  }

  void _applyGenericPresenceUpdate(Map<String, dynamic> data) {
    final users = _extractUsersList(data);
    if (users != null) {
      final updatedUsers = Set<String>.from(onlineUsers.value);
      var changed = false;

      for (final user in users) {
        final userId = _extractUserId(user);
        if (userId.isEmpty || user is! Map) continue;

        final userData = Map<String, dynamic>.from(user);
        if (!_hasOnlineFlag(userData)) continue;

        if (_extractOnlineFlag(userData)) {
          changed = updatedUsers.add(userId) || changed;
        } else {
          changed = updatedUsers.remove(userId) || changed;
        }
      }

      if (changed) {
        _setOnlineUsers(updatedUsers);
        debugPrint("PRESENCE LIST UPDATE => ${onlineUsers.value}");
      }
      return;
    }

    if (!_hasOnlineFlag(data)) return;

    final userId = _extractUserId(data);
    if (userId.isEmpty) return;

    final updatedUsers = Set<String>.from(onlineUsers.value);
    final wasOnline = updatedUsers.contains(userId);
    final isOnline = _extractOnlineFlag(data);

    if (isOnline) {
      updatedUsers.add(userId);
    } else {
      updatedUsers.remove(userId);
    }

    if (wasOnline != isOnline) {
      _setOnlineUsers(updatedUsers);
      debugPrint("GENERIC PRESENCE => $userId online=$isOnline");
    }
  }

  List<dynamic>? _extractUsersList(Map<String, dynamic> data) {
    final candidates = [
      data['users'],
      data['online_users'],
      data['onlineUsers'],
      if (data['data'] is Map) (data['data'] as Map)['users'],
      if (data['data'] is Map) (data['data'] as Map)['online_users'],
      if (data['data'] is Map) (data['data'] as Map)['onlineUsers'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) return candidate;
    }

    return null;
  }

  String _extractUserId(dynamic source) {
    if (source == null) return '';

    if (source is String || source is num) {
      return source.toString().trim();
    }

    if (source is! Map) return '';

    final data = Map<String, dynamic>.from(source);
    final direct = _firstString(data, const [
      'user_id',
      'userId',
      'id',
      '_id',
      'pk',
    ]);
    if (direct.isNotEmpty) return direct;

    for (final key in const ['user', 'profile', 'data']) {
      final nested = data[key];
      if (nested is Map || nested is String || nested is num) {
        final nestedId = _extractUserId(nested);
        if (nestedId.isNotEmpty) return nestedId;
      }
    }

    return '';
  }

  bool _extractOnlineFlag(Map<String, dynamic> data) {
    for (final key in const [
      'is_online',
      'isOnline',
      'online',
      'status',
      'presence',
      'state',
    ]) {
      final value = data[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' ||
            normalized == '1' ||
            normalized == 'online') {
          return true;
        }
        if (normalized == 'false' ||
            normalized == '0' ||
            normalized == 'offline' ||
            normalized == 'disconnected' ||
            normalized == 'inactive') {
          return false;
        }
      }
    }

    for (final key in const ['user', 'profile', 'data']) {
      final nested = data[key];
      if (nested is Map) {
        final nestedData = Map<String, dynamic>.from(nested);
        if (_hasOnlineFlag(nestedData)) {
          return _extractOnlineFlag(nestedData);
        }
      }
    }

    return true;
  }

  bool _hasOnlineFlag(Map<String, dynamic> data) {
    if (data.containsKey('is_online') ||
        data.containsKey('isOnline') ||
        data.containsKey('online') ||
        data.containsKey('status') ||
        data.containsKey('presence') ||
        data.containsKey('state')) {
      return true;
    }

    for (final key in const ['user', 'profile', 'data']) {
      final nested = data[key];
      if (nested is Map && _hasOnlineFlag(Map<String, dynamic>.from(nested))) {
        return true;
      }
    }

    return false;
  }

  String _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  void _setOnlineUsers(Set<String> users) {
    onlineUsers.value = users
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  // =========================
  // PUBLIC METHODS
  // =========================

  /// Connect to WebSocket (maintains backward compatibility)
  Future<void> connect(String token) async {
    debugPrint("[SOCKET SERVICE] connect() requested");
    debugPrint("🔌 [SocketService] 🔌 CONNECTING SOCKET...");
    final previewLength = token.length < 10 ? token.length : 10;
    debugPrint(
      "🎫 [SocketService] 🎫 Token preview: ${token.substring(0, previewLength)}...",
    );

    await _reconnectManager.connect(token);
    debugPrint(
      "[SOCKET SERVICE] connect() completed state=${_reconnectManager.state.name}",
    );
  }

  /// Send message through enhanced socket with timeout protection
  /// Returns true if message was successfully queued, false otherwise
  bool sendMessage({
    required String conversationId,
    required String message,
    String? senderId,
    Map<String, dynamic>? additionalData,
  }) {
    debugPrint(
      "[SOCKET SERVICE] sendMessage() state=${_reconnectManager.state.name} connected=${_reconnectManager.isConnected}",
    );
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

    debugPrint("[SOCKET SERVICE] outgoing payload => $messageData");

    try {
      debugPrint("🚀 [SocketService] 🚀 Attempting to send via WebSocket...");
      final sent = _reconnectManager.sendMessage(messageData);
      debugPrint("[SOCKET SERVICE] low-level send result => $sent");

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

  Future<void> reconnectWithLatestTokenIfActive() async {
    if (!_reconnectManager.isConnected && !_reconnectManager.isConnecting) {
      return;
    }

    debugPrint('[SocketService] Refreshing socket auth with latest token');
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
