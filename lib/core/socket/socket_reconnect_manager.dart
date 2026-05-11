import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/core/debug/debug_logger.dart';

/// WebSocket connection states
enum SocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// WebSocket event types
enum SocketEventType {
  connected,
  disconnected,
  message,
  error,
  reconnecting,
  failed,
}

/// WebSocket event data
class SocketEvent {
  final SocketEventType type;
  final dynamic data;
  final DateTime timestamp;

  SocketEvent({
    required this.type,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Production-grade WebSocket reconnect manager
/// Handles exponential backoff, heartbeat, and connection state management
class SocketReconnectManager {
  static final SocketReconnectManager _instance = SocketReconnectManager._internal();
  factory SocketReconnectManager() => _instance;
  SocketReconnectManager._internal() {
    _initializeConnectivityListener();
  }

  // =========================
  // CONFIGURATION
  // =========================

  static const String _baseUrl = "ws://zg7h02xx-8000.inc1.devtunnels.ms/ws";
  static const Duration _heartbeatInterval = Duration(seconds: 25);
  static const Duration _connectionTimeout = Duration(seconds: 15);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 10;

  // =========================
  // STATE VARIABLES
  // =========================

  SocketState _state = SocketState.disconnected;
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _connectionTimeoutTimer;

  int _reconnectAttempts = 0;
  DateTime? _lastConnectedAt;
  DateTime? _lastHeartbeatSent;
  DateTime? _lastHeartbeatReceived;

  // =========================
  // STREAM CONTROLLERS
  // =========================

  final StreamController<SocketEvent> _eventController = 
      StreamController<SocketEvent>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // =========================
  // GETTERS
  // =========================

  SocketState get state => _state;
  bool get isConnected => _state == SocketState.connected;
  bool get isConnecting => _state == SocketState.connecting || _state == SocketState.reconnecting;
  bool get isDisconnected => _state == SocketState.disconnected || _state == SocketState.failed;
  int get reconnectAttempts => _reconnectAttempts;
  DateTime? get lastConnectedAt => _lastConnectedAt;

  // Public streams
  Stream<SocketEvent> get events => _eventController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  // =========================
  // PUBLIC METHODS
  // =========================

  /// Connect to WebSocket with automatic reconnection
  Future<void> connect() async {
    debugLog.socket('CONNECT_ATTEMPT', properties: {
      'currentState': _state.name,
      'reconnectAttempts': _reconnectAttempts,
      'lastConnected': _lastConnectedAt?.toIso8601String(),
    });

    if (isConnected) {
      debugLog.socket('ALREADY_CONNECTED', properties: {'reason': 'Connection already established'});
      return;
    }

    if (isConnecting) {
      debugLog.socket('CONNECTION_IN_PROGRESS', properties: {'reason': 'Connection already in progress'});
      return;
    }

    await _performConnect();
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    debugLog.socket('DISCONNECT', properties: {
      'reason': 'Manual disconnect',
      'connectionDuration': _lastConnectedAt != null 
          ? DateTime.now().difference(_lastConnectedAt!).inMilliseconds 
          : null,
    });
    
    _clearReconnectTimer();
    _clearHeartbeatTimer();
    _clearConnectionTimeoutTimer();
    
    _setState(SocketState.disconnected);
    _reconnectAttempts = 0;

    await _socketSubscription?.cancel();
    _socketSubscription = null;

    await _channel?.sink.close();
    _channel = null;

    debugLog.socket('DISCONNECT_COMPLETE', properties: {'reason': 'Manual disconnect complete'});
    _emitEvent(SocketEvent(type: SocketEventType.disconnected));
  }

  /// Send message through WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (!isConnected || _channel == null) {
      debugPrint('❌ [SocketReconnect] Cannot send message - not connected');
      return;
    }

    try {
      final jsonString = _encodeMessage(message);
      _channel!.sink.add(jsonString);
      debugPrint('📤 [SocketReconnect] Message sent: ${message['conversation_id']}');
    } catch (e) {
      debugPrint('❌ [SocketReconnect] Send message error: $e');
    }
  }

  /// Reset connection state (useful for token changes)
  Future<void> reset() async {
    debugPrint('🔄 [SocketReconnect] Resetting connection');
    await disconnect();
    _reconnectAttempts = 0;
    await connect();
  }

  // =========================
  // PRIVATE METHODS
  // =========================

  Future<void> _performConnect() async {
    try {
      _setState(SocketState.connecting);
      _clearReconnectTimer();

      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ [SocketReconnect] No auth token available');
        _setState(SocketState.failed);
        _scheduleReconnect();
        return;
      }

      final socketUrl = '$_baseUrl?token=$token';
      debugPrint('🔌 [SocketReconnect] Connecting to: ${socketUrl.split('?')[0]}...');

      // Set connection timeout
      _connectionTimeoutTimer = Timer(_connectionTimeout, () {
        debugPrint('⏰ [SocketReconnect] Connection timeout');
        _handleConnectionError('Connection timeout');
      });

      _channel = WebSocketChannel.connect(Uri.parse(socketUrl));
      _lastConnectedAt = DateTime.now();

      await _setupSocketListeners();
      
    } catch (e) {
      debugPrint('❌ [SocketReconnect] Connection error: $e');
      _handleConnectionError(e.toString());
    }
  }

  Future<void> _setupSocketListeners() async {
    await _socketSubscription?.cancel();
    
    _socketSubscription = _channel?.stream.listen(
      _onMessageReceived,
      onDone: _onConnectionClosed,
      onError: _onConnectionError,
    );

    debugPrint('👂 [SocketReconnect] Socket listeners setup complete');
  }

  void _onMessageReceived(dynamic message) {
    try {
      final data = _decodeMessage(message);
      if (data != null) {
        _messageController.add(data);
        
        // Handle heartbeat response
        if (data['type'] == 'pong') {
          _lastHeartbeatReceived = DateTime.now();
          debugPrint('💓 [SocketReconnect] Heartbeat received');
          return;
        }

        debugPrint('📨 [SocketReconnect] Message received: ${data['type']}');
      }
    } catch (e) {
      debugPrint('❌ [SocketReconnect] Message parse error: $e');
    }
  }

  void _onConnectionClosed() {
    debugPrint('🔌 [SocketReconnect] Connection closed');
    _setState(SocketState.disconnected);
    _clearHeartbeatTimer();
    _emitEvent(SocketEvent(type: SocketEventType.disconnected));
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      debugPrint('❌ [SocketReconnect] Max reconnect attempts reached');
      _setState(SocketState.failed);
      _emitEvent(SocketEvent(type: SocketEventType.failed));
    }
  }

  void _onConnectionError(dynamic error) {
    debugPrint('❌ [SocketReconnect] Connection error: $error');
    _handleConnectionError(error.toString());
  }

  void _handleConnectionError(String error) {
    _clearConnectionTimeoutTimer();
    _setState(SocketState.failed);
    _emitEvent(SocketEvent(type: SocketEventType.error, data: error));
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      debugPrint('❌ [SocketReconnect] Max reconnect attempts reached');
      _setState(SocketState.failed);
      _emitEvent(SocketEvent(type: SocketEventType.failed));
    }
  }

  void _scheduleReconnect() {
    if (isConnecting) return;

    final delay = _calculateReconnectDelay();
    debugPrint('⏰ [SocketReconnect] Scheduling reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(delay, () async {
      _reconnectAttempts++;
      _setState(SocketState.reconnecting);
      _emitEvent(SocketEvent(type: SocketEventType.reconnecting, data: _reconnectAttempts));
      
      await _performConnect();
    });
  }

  Duration _calculateReconnectDelay() {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, max 30s
    final baseDelay = Duration(seconds: 1);
    final exponentialDelay = baseDelay * (1 << (_reconnectAttempts - 1));
    
    return exponentialDelay > _maxReconnectDelay ? _maxReconnectDelay : exponentialDelay;
  }

  void _startHeartbeat() {
    _clearHeartbeatTimer();
    
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        _sendHeartbeat();
      } else {
        timer.cancel();
      }
    });
  }

  void _sendHeartbeat() {
    final heartbeat = {
      'type': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    sendMessage(heartbeat);
    _lastHeartbeatSent = DateTime.now();
    debugLog.socket('HEARTBEAT_SENT', properties: {
      'timestamp': heartbeat['timestamp'],
      'interval': _heartbeatInterval.inSeconds,
    });
    debugPrint('💓 [SocketReconnect] Heartbeat sent');
  }

  void _initializeConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      debugLog.socket('CONNECTIVITY_CHANGE', properties: {
        'result': result.name,
        'isConnected': isConnected.toString(),
        'isDisconnected': isDisconnected.toString(),
      });
      
      if (result != ConnectivityResult.none && isDisconnected) {
        debugLog.socket('INTERNET_RESTORED', properties: {'action': 'reconnecting'});
        reset();
      } else if (result == ConnectivityResult.none && isConnected) {
        debugLog.socket('INTERNET_LOST', properties: {'action': 'will_reconnect_when_restored'});
      }
    });
  }

  void _setState(SocketState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      debugLog.socket('STATE_CHANGE', properties: {
        'from': oldState.name,
        'to': newState.name,
        'reconnectAttempts': _reconnectAttempts,
        'connectionDuration': _lastConnectedAt != null 
            ? DateTime.now().difference(_lastConnectedAt!).inMilliseconds 
            : null,
      });
      
      if (newState == SocketState.connected) {
        _reconnectAttempts = 0;
        _startHeartbeat();
        _clearConnectionTimeoutTimer();
        _emitEvent(SocketEvent(type: SocketEventType.connected));
      }
    }
  }

  void _emitEvent(SocketEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  // =========================
  // CLEANUP METHODS
  // =========================

  void _clearReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _clearHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _clearConnectionTimeoutTimer() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  // =========================
  // UTILITY METHODS
  // =========================

  String _encodeMessage(Map<String, dynamic> message) {
    try {
      return message.toString(); // Simple string encoding for now
    } catch (e) {
      debugPrint('❌ [SocketReconnect] Message encode error: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? _decodeMessage(dynamic message) {
    try {
      if (message is String) {
        // Simple parse for now - upgrade to JSON if needed
        return {'type': 'message', 'content': message};
      }
      return message as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ [SocketReconnect] Message decode error: $e');
      return null;
    }
  }

  // =========================
  // DISPOSE
  // =========================

  Future<void> dispose() async {
    debugPrint('🗑️ [SocketReconnect] Disposing socket manager');
    
    await disconnect();
    
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    
    await _eventController.close();
    await _messageController.close();
  }
}
