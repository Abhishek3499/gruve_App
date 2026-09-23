import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/socket/socket_event.dart';
import 'package:gruve_app/core/socket/reconnect_backoff.dart';
import 'package:gruve_app/core/socket/socket_logger.dart';

export 'package:gruve_app/core/socket/socket_event.dart';

/// SocketReconnectManager
/// Manages WebSocket connection, exponential backoff reconnects, and lifecycle states.
class SocketReconnectManager with WidgetsBindingObserver {
  static final SocketReconnectManager _instance =
      SocketReconnectManager._internal();
  factory SocketReconnectManager() => _instance;

  SocketReconnectManager._internal() {
    WidgetsBinding.instance.addObserver(this);
    _initializeConnectivityListener();
  }

  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const ReconnectBackoff _backoff = ReconnectBackoff();

  SocketState _state = SocketState.disconnected;
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _manualDisconnect = false;
  bool _isAuthenticated = false;

  final StreamController<SocketEvent> _eventController =
      StreamController<SocketEvent>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  // ==========================================
  // Public Getters & Streams
  // ==========================================

  SocketState get state => _state;
  bool get isConnected => _state == SocketState.connected;
  Stream<SocketEvent> get events => _eventController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Sets auth state to prevent reconnect attempts when logged out
  void setAuthState(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
    if (!isAuthenticated) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _reconnectAttempts = 0;
    }
  }

  // ==========================================
  // Connection Management
  // ==========================================

  Future<void> connect() async {
    if (_state == SocketState.connected || _state == SocketState.connecting) {
      return;
    }

    _manualDisconnect = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _performConnect();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;

    await _cleanupSocket();
    _setState(SocketState.disconnected);
    _emitEvent(SocketEvent(type: SocketEventType.disconnected));
    SocketLogger.disconnect(reason: 'manual');
  }

  bool send(Map<String, dynamic> data) {
    if (!isConnected || _channel == null) {
      SocketLogger.error('Cannot send message - not connected');
      return false;
    }

    try {
      final jsonString = jsonEncode(data);
      _channel!.sink.add(jsonString);
      SocketLogger.send(data);
      return true;
    } catch (e) {
      SocketLogger.error('Error sending message: $e');
      return false;
    }
  }

  // ==========================================
  // Private Connection Logic
  // ==========================================

  Future<void> _performConnect() async {
    if (!_isAuthenticated) {
      _setState(SocketState.disconnected);
      return;
    }

    _setState(SocketState.connecting);
    final reconnectAttempt = _reconnectAttempts;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.trim().isEmpty) {
        _setState(SocketState.disconnected);
        return;
      }

      final wsUrl = EnvironmentConfig.wsUrl;
      final uri = Uri.parse(
        wsUrl,
      ).replace(queryParameters: {'token': token.trim()});

      if (reconnectAttempt == 0) {
        SocketLogger.connect(wsUrl);
      }
      await _cleanupSocket();

      _channel = IOWebSocketChannel.connect(
        uri,
        connectTimeout: _connectionTimeout,
      );

      _socketSubscription = _channel!.stream.listen(
        _onMessageReceived,
        onError: _onSocketError,
        onDone: _onSocketDone,
        cancelOnError: false,
      );

      _reconnectAttempts = 0;
      _setState(SocketState.connected);
      _emitEvent(SocketEvent(type: SocketEventType.connected));
      if (reconnectAttempt > 0) {
        SocketLogger.reconnectSuccess(reconnectAttempt);
      } else {
        SocketLogger.connected(wsUrl);
      }
    } catch (e) {
      if (reconnectAttempt > 0) {
        SocketLogger.reconnectError(reconnectAttempt, e.toString());
      } else {
        SocketLogger.error('Connect failed: $e');
      }
      _cleanupSocket();
      _handleDisconnectOrError();
    }
  }

  void _onMessageReceived(dynamic message) {
    try {
      final decoded = jsonDecode(message.toString());
      if (decoded is Map<String, dynamic>) {
        SocketLogger.receive(decoded);
        _messageController.add(decoded);
        _emitEvent(SocketEvent(type: SocketEventType.message, data: decoded));
      }
    } catch (e) {
      SocketLogger.error('Failed to parse message: $e');
    }
  }

  void _onSocketError(dynamic error) {
    SocketLogger.error('Stream error: $error');
    _emitEvent(SocketEvent(type: SocketEventType.error, data: error));
    _handleDisconnectOrError();
  }

  void _onSocketDone() {
    SocketLogger.disconnect(reason: 'connection_closed');
    _handleDisconnectOrError();
  }

  void _handleDisconnectOrError() {
    if (_manualDisconnect || !_isAuthenticated) {
      _setState(SocketState.disconnected);
      _emitEvent(SocketEvent(type: SocketEventType.disconnected));
      return;
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_backoff.isExhausted(_reconnectAttempts)) {
      SocketLogger.reconnectError(
        _reconnectAttempts,
        'Max reconnect attempts reached',
      );
      _setState(SocketState.failed);
      _emitEvent(SocketEvent(type: SocketEventType.failed));
      return;
    }

    _reconnectAttempts++;
    final delay = _backoff.delayForAttempt(_reconnectAttempts);

    SocketLogger.reconnecting(_reconnectAttempts);
    _setState(SocketState.reconnecting);
    _emitEvent(
      SocketEvent(type: SocketEventType.reconnecting, data: _reconnectAttempts),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => _performConnect());
  }

  Future<void> _cleanupSocket() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _setState(SocketState newState) {
    if (_state != newState) {
      _state = newState;
    }
  }

  void _emitEvent(SocketEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  // ==========================================
  // Connectivity & App Lifecycle
  // ==========================================

  void _initializeConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      if (result != ConnectivityResult.none &&
          _isAuthenticated &&
          !isConnected &&
          !_manualDisconnect) {
        _reconnectAttempts = 0;
        connect();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isAuthenticated &&
        !isConnected &&
        !_manualDisconnect) {
      _reconnectAttempts = 0;
      connect();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _reconnectTimer?.cancel();
    _cleanupSocket();
    _eventController.close();
    _messageController.close();
  }
}
