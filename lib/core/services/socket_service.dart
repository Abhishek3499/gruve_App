import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:gruve_app/core/socket/socket_reconnect_manager.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    AppLogger.d("✅ [SocketService] ✅ SOCKET CONNECTED SUCCESSFULLY");
    AppLogger.d("🎉 [SocketService] 🎉 WebSocket connection established");
    if (connectionTime != null) {
      developer.log(
        '🔌 [PERF] Socket connected at: ${connectionTime.toIso8601String()}',
        name: 'SocketService',
      );
    }
  }

  void _onDisconnected() {
    _setOnlineUsers(<String>{});
    AppLogger.d("[SocketService] SOCKET CONNECTION CLOSED");
    AppLogger.d(
      "[SocketService] Connection ended, will reconnect automatically",
    );
  }

  void _onReconnecting(int attempt) {
    AppLogger.d("[SocketService] RECONNECTING ATTEMPT $attempt");
    AppLogger.d("⏳ [SocketService] ⏳ Attempting to restore connection...");
  }

  void _onFailed() {
    _setOnlineUsers(<String>{});
    AppLogger.d("❌ [SocketService] ❌ CONNECTION FAILED");
    AppLogger.d("[SocketService] Max reconnect attempts reached");
  }

  void _onError(String error) {
    AppLogger.d("💥 [SocketService] 💥 SOCKET ERROR => $error");
    AppLogger.d("❌ [SocketService] ❌ Connection error occurred");
  }

  // ADD HERE 👇👇👇

  void _handleSocketMessage(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    AppLogger.d("📩 [SocketService] Message Type => $type");

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

        AppLogger.d("🟢 ONLINE USERS => ${onlineUsers.value}");

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

          AppLogger.d("🟢 USER ONLINE => $userId");
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

          AppLogger.d("🔴 USER OFFLINE => $userId");
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
          AppLogger.d(
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
        AppLogger.d("PRESENCE LIST UPDATE => ${onlineUsers.value}");
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
      AppLogger.d("GENERIC PRESENCE => $userId online=$isOnline");
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
    AppLogger.d("[SOCKET SERVICE] connect() requested");
    AppLogger.d("🔌 [SocketService] 🔌 CONNECTING SOCKET...");
    final previewLength = token.length < 10 ? token.length : 10;
    AppLogger.d(
      "🎫 [SocketService] 🎫 Token preview: ${token.substring(0, previewLength)}...",
    );

    await _reconnectManager.connect(token);
    AppLogger.d(
      "[SOCKET SERVICE] connect() completed state=${_reconnectManager.state.name}",
    );
  }

  /// Send chat message through WebSocket (`chat.send`).
  /// Supports text-only, media-only, text+media, and replies.
  bool sendMessage({
    required String conversationId,
    String? content,
    String? replyToMessageId,
    Map<String, dynamic>? media,
    String? senderId,
    Map<String, dynamic>? additionalData,
  }) {
    AppLogger.d(
      "[SOCKET SERVICE] sendMessage() state=${_reconnectManager.state.name} connected=${_reconnectManager.isConnected}",
    );

    final trimmedContent = content?.trim() ?? '';
    if (trimmedContent.isEmpty && media == null) {
      AppLogger.d("⚠️ [SocketService] ⚠️ EMPTY MESSAGE - Nothing to send");
      return false;
    }

    if (!_reconnectManager.isConnected) {
      AppLogger.d(
        "⚠️ [SocketService] ⚠️ WEBSOCKET NOT CONNECTED - Message not sent",
      );
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

    AppLogger.d("[SOCKET SERVICE] outgoing payload => $messageData");

    try {
      final sent = _reconnectManager.sendMessage(messageData);
      return sent;
    } catch (e) {
      AppLogger.d("❌ [SocketService] ❌ FAILED TO SEND MESSAGE: $e");
      return false;
    }
  }

  /// Send an event map directly via WebSocket (e.g. read receipt)
  bool sendEvent(Map<String, dynamic> eventData) {
    if (!_reconnectManager.isConnected) {
      AppLogger.d("⚠️ [SocketService] ⚠️ WEBSOCKET NOT CONNECTED - Event not sent");
      return false;
    }

    try {
      AppLogger.d("🚀 [SocketService] 🚀 Sending event via WebSocket: ${eventData['type']}");
      final sent = _reconnectManager.sendMessage(eventData);
      return sent;
    } catch (e) {
      AppLogger.d("❌ [SocketService] ❌ FAILED TO SEND EVENT: $e");
      return false;
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    AppLogger.d("🔌 [SocketService] 🔌 DISCONNECTING SOCKET...");
    AppLogger.d("👋 [SocketService] 👋 Closing connection");

    await _reconnectManager.disconnect();

    AppLogger.d("✅ [SocketService] ✅ SOCKET DISCONNECTED SUCCESSFULLY");
  }

  /// Reset connection (useful for token changes)
  Future<void> reset() async {
    AppLogger.d("🔄 [SocketService] 🔄 RESETTING CONNECTION");
    await _reconnectManager.reset();
  }

  Future<void> reconnectWithLatestTokenIfActive() async {
    if (!_reconnectManager.isConnected && !_reconnectManager.isConnecting) {
      return;
    }

    AppLogger.d('[SocketService] Refreshing socket auth with latest token');
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

  /// Updates the socket layer's authentication state.
  ///
  /// Call with `true` after a successful login / session restore so that
  /// the reconnect loop is allowed to run. Call with `false` on logout so
  /// the loop stops immediately and cannot restart from connectivity or
  /// lifecycle events. See [SocketReconnectManager.setAuthState] for details.
  void setAuthState(bool authenticated) {
    _reconnectManager.setAuthState(authenticated);
  }

  /// Listen to socket events for advanced UI handling
  Stream<SocketEvent> get events => _reconnectManager.events;

  // =========================
  // DISPOSE
  // =========================

  Future<void> dispose() async {
    AppLogger.d("🗑️ [SocketService] 🗑️ DISPOSING SOCKET SERVICE");

    await _eventSubscription?.cancel();
    _eventSubscription = null;

    await _reconnectManager.dispose();

    AppLogger.d("✅ [SocketService] ✅ SOCKET SERVICE DISPOSED");
  }
}
