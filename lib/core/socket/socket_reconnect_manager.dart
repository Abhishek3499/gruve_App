import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/debug/debug_logger.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

enum SocketEventType {
  connected,
  disconnected,
  message,
  error,
  reconnecting,
  failed,
}

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

class SocketReconnectManager with WidgetsBindingObserver {
  static final SocketReconnectManager _instance =
      SocketReconnectManager._internal();
  factory SocketReconnectManager() => _instance;

  SocketReconnectManager._internal() {
    WidgetsBinding.instance.addObserver(this);
    _initializeConnectivityListener();
  }

  // Use centralized WebSocket URL from EnvironmentConfig
  static String get _baseUrl => EnvironmentConfig.wsUrl;
  static const Duration _heartbeatInterval = Duration(seconds: 25);
  static const Duration _connectionTimeout = Duration(seconds: 15);
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 10;

  SocketState _state = SocketState.disconnected;
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _connectionTimeoutTimer;

  int _reconnectAttempts = 0;
  bool _manualDisconnect = false;
  bool _isDisposed = false;
  bool _isOnline = true;
  bool _isAppInForeground = true;
  DateTime? _lastConnectedAt;
  DateTime? _lastHeartbeatSent;
  DateTime? _lastHeartbeatReceived;

  final StreamController<SocketEvent> _eventController =
      StreamController<SocketEvent>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  SocketState get state => _state;
  bool get isConnected => _state == SocketState.connected;
  bool get isConnecting =>
      _state == SocketState.connecting || _state == SocketState.reconnecting;
  bool get isDisconnected =>
      _state == SocketState.disconnected || _state == SocketState.failed;
  int get reconnectAttempts => _reconnectAttempts;
  DateTime? get lastConnectedAt => _lastConnectedAt;

  Stream<SocketEvent> get events => _eventController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<void> connect() async {
    if (_isDisposed) {
      debugLog.socket('CONNECT_IGNORED', properties: {'reason': 'disposed'});
      return;
    }

    _manualDisconnect = false;
    debugLog.socket('CONNECT_ATTEMPT', properties: {
      'currentState': _state.name,
      'reconnectAttempts': _reconnectAttempts,
      'lastConnected': _lastConnectedAt?.toIso8601String(),
    });

    if (isConnected) {
      debugLog.socket(
        'ALREADY_CONNECTED',
        properties: {'reason': 'Connection already established'},
      );
      return;
    }

    if (isConnecting) {
      debugLog.socket(
        'CONNECTION_IN_PROGRESS',
        properties: {'reason': 'Connection already in progress'},
      );
      return;
    }

    await _performConnect();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    debugLog.socket('DISCONNECT', properties: {
      'reason': 'manual',
      'connectionDurationMs': _lastConnectedAt == null
          ? null
          : DateTime.now().difference(_lastConnectedAt!).inMilliseconds,
    });

    _clearReconnectTimer();
    await _cleanupActiveSocket();
    _reconnectAttempts = 0;
    _setState(SocketState.disconnected);

    debugLog.socket('DISCONNECT_COMPLETE');
    _emitEvent(SocketEvent(type: SocketEventType.disconnected));
  }

  bool sendMessage(Map<String, dynamic> message) {
    if (!isConnected || _channel == null) {
      debugLog.socket('SEND_SKIPPED', properties: {'reason': 'not_connected'});
      return false;
    }

    try {
      _channel!.sink.add(jsonEncode(message));
      debugLog.socket('MESSAGE_SENT', properties: {
        'conversationId': message['conversation_id'],
        'type': message['type'],
      });
      return true;
    } catch (error) {
      debugLog.socket('SEND_ERROR', error: error.toString());
      return false;
    }
  }

  Future<void> reset() async {
    debugLog.socket('RESET');
    _manualDisconnect = false;
    _clearReconnectTimer();
    await _cleanupActiveSocket();
    _reconnectAttempts = 0;
    await connect();
  }

  Future<void> _performConnect() async {
    if (_isDisposed || _manualDisconnect) {
      debugLog.socket('CONNECT_CANCELLED', properties: {
        'disposed': _isDisposed,
        'manualDisconnect': _manualDisconnect,
      });
      return;
    }

    if (!_isOnline || !_isAppInForeground) {
      debugLog.socket('CONNECT_DEFERRED', properties: {
        'isOnline': _isOnline,
        'isAppInForeground': _isAppInForeground,
      });
      _setState(SocketState.disconnected);
      return;
    }

    try {
      _setState(SocketState.connecting);
      _clearReconnectTimer();
      await _cleanupActiveSocket(keepState: true);

      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        debugLog.socket('CONNECT_FAILED', error: 'Missing auth token');
        _setState(SocketState.failed);
        _scheduleReconnect();
        return;
      }

      final socketUrl = '$_baseUrl?token=$token';
      
      // Enhanced logging for WebSocket URL debugging
      debugLog.socket('CONFIG_CHECK', properties: {
        'environment': EnvironmentConfig.environment.name,
        'wsUrl': _baseUrl,
        'baseUrl': EnvironmentConfig.baseUrl,
        'isProduction': EnvironmentConfig.isProduction,
      });
      
      debugLog.socket('CONNECTING', properties: {
        'fullUrl': socketUrl,
        'wsUrl': _baseUrl,
        'tokenLength': token.length,
      });

      _connectionTimeoutTimer = Timer(_connectionTimeout, () {
        debugLog.socket('CONNECT_TIMEOUT', properties: {
          'timeoutMs': _connectionTimeout.inMilliseconds,
        });
        _handleConnectionError('Connection timeout');
      });

      // ✅ BUG FIX: Ensure proper WebSocket URI with wss:// protocol (no port override)
      final uri = Uri.parse(socketUrl);
      debugLog.socket('URI_PARSED', properties: {
        'scheme': uri.scheme,
        'host': uri.host,
        'port': uri.hasPort ? uri.port : 'default',
        'path': uri.path,
        'query': uri.query,
      });

      _channel = WebSocketChannel.connect(uri);
      await _setupSocketListeners();

      _lastConnectedAt = DateTime.now();
      _setState(SocketState.connected);
    } catch (error, stackTrace) {
      debugLog.socket('CONNECT_ERROR', error: error.toString());
      debugLog.error(
        'Socket connect failed',
        tag: 'Socket',
        errorObj: error,
        stackTraceObj: stackTrace,
      );
      _handleConnectionError(error.toString());
    }
  }

  Future<void> _setupSocketListeners() async {
    await _socketSubscription?.cancel();

    _socketSubscription = _channel?.stream.listen(
      _onMessageReceived,
      onDone: _onConnectionClosed,
      onError: _onConnectionError,
      cancelOnError: false,
    );

    debugLog.socket('LISTENERS_ATTACHED');
  }

  void _onMessageReceived(dynamic message) {
    try {
      final data = _decodeMessage(message);
      if (data == null) return;

      if (data['type'] == 'pong') {
        _lastHeartbeatReceived = DateTime.now();
        debugLog.socket('HEARTBEAT_RECEIVED');
        return;
      }

      _messageController.add(data);
      _emitEvent(SocketEvent(type: SocketEventType.message, data: data));
      debugLog.socket('MESSAGE_RECEIVED', properties: {'type': data['type']});
    } catch (error) {
      debugLog.socket('MESSAGE_PARSE_ERROR', error: error.toString());
    }
  }

  void _onConnectionClosed() {
    if (_manualDisconnect || _isDisposed) {
      debugLog.socket('CLOSE_IGNORED', properties: {
        'manualDisconnect': _manualDisconnect,
        'disposed': _isDisposed,
      });
      return;
    }

    debugLog.socket('DISCONNECTED', properties: {'reason': 'stream_done'});
    _setState(SocketState.disconnected);
    _clearHeartbeatTimer();
    _clearConnectionTimeoutTimer();
    _emitEvent(SocketEvent(type: SocketEventType.disconnected));
    _scheduleReconnect();
  }

  void _onConnectionError(dynamic error) {
    debugLog.socket('STREAM_ERROR', error: error.toString());
    _handleConnectionError(error.toString());
  }

  void _handleConnectionError(String error) {
    if (_manualDisconnect || _isDisposed) {
      debugLog.socket('ERROR_IGNORED', error: error, properties: {
        'manualDisconnect': _manualDisconnect,
        'disposed': _isDisposed,
      });
      return;
    }

    _clearConnectionTimeoutTimer();
    _clearHeartbeatTimer();
    _setState(SocketState.failed);
    _emitEvent(SocketEvent(type: SocketEventType.error, data: error));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed || _manualDisconnect) {
      debugLog.socket('RECONNECT_SKIPPED', properties: {
        'reason': _isDisposed ? 'disposed' : 'manual_disconnect',
      });
      return;
    }

    if (!_isOnline || !_isAppInForeground) {
      debugLog.socket('RECONNECT_DEFERRED', properties: {
        'isOnline': _isOnline,
        'isAppInForeground': _isAppInForeground,
      });
      _setState(SocketState.disconnected);
      return;
    }

    if (_reconnectTimer != null || isConnecting) {
      debugLog.socket('RECONNECT_SKIPPED', properties: {
        'reason': _reconnectTimer != null ? 'timer_exists' : 'already_connecting',
      });
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugLog.socket(
        'RECONNECT_GIVE_UP',
        reconnectAttempts: _reconnectAttempts,
      );
      _setState(SocketState.failed);
      _emitEvent(SocketEvent(type: SocketEventType.failed));
      return;
    }

    final nextAttempt = (_reconnectAttempts + 1).clamp(1, _maxReconnectAttempts);
    final delay = _calculateReconnectDelay();
    debugLog.socket('RECONNECT_SCHEDULED', reconnectAttempts: nextAttempt,
        properties: {
          'delayMs': delay.inMilliseconds,
          'capMs': _maxReconnectDelay.inMilliseconds,
        });

    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      _reconnectAttempts =
          (_reconnectAttempts + 1).clamp(1, _maxReconnectAttempts);
      _setState(SocketState.reconnecting);
      _emitEvent(
        SocketEvent(type: SocketEventType.reconnecting, data: _reconnectAttempts),
      );

      await _performConnect();
    });
  }

  Duration _calculateReconnectDelay() {
    final safeAttempts = math.max(0, _reconnectAttempts);
    final exponent = math.min(safeAttempts, 5);
    final exponentialDelay = _baseReconnectDelay * (1 << exponent);
    return exponentialDelay > _maxReconnectDelay
        ? _maxReconnectDelay
        : exponentialDelay;
  }

  void _startHeartbeat() {
    _clearHeartbeatTimer();

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      _sendHeartbeat();
    });
  }

  void _sendHeartbeat() {
    sendMessage({
      'type': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _lastHeartbeatSent = DateTime.now();
    debugLog.socket('HEARTBEAT_SENT', properties: {
      'intervalMs': _heartbeatInterval.inMilliseconds,
    });
  }

  void _initializeConnectivityListener() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      debugLog.socket('CONNECTIVITY_CHANGE', properties: {
        'result': result.name,
        'isOnline': _isOnline,
        'state': _state.name,
      });

      if (_isOnline && isDisconnected && !_manualDisconnect) {
        _reconnectAttempts = 0;
        _scheduleReconnect();
      } else if (!_isOnline) {
        _clearReconnectTimer();
        _clearHeartbeatTimer();
        if (isConnected) {
          _setState(SocketState.disconnected);
          _emitEvent(SocketEvent(type: SocketEventType.disconnected));
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasInForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;

    debugLog.socket('APP_LIFECYCLE', properties: {
      'state': state.name,
      'wasInForeground': wasInForeground,
      'isAppInForeground': _isAppInForeground,
    });

    if (!_isAppInForeground) {
      _clearReconnectTimer();
      _clearHeartbeatTimer();
      return;
    }

    if (!wasInForeground && !_manualDisconnect && !isConnected) {
      _reconnectAttempts = 0;
      _scheduleReconnect();
    } else if (isConnected) {
      _startHeartbeat();
    }
  }

  void _setState(SocketState newState) {
    if (_state == newState) return;

    final oldState = _state;
    _state = newState;
    debugLog.socket('STATE_CHANGE', properties: {
      'from': oldState.name,
      'to': newState.name,
      'reconnectAttempts': _reconnectAttempts,
      'connectionDurationMs': _lastConnectedAt == null
          ? null
          : DateTime.now().difference(_lastConnectedAt!).inMilliseconds,
    });

    if (newState == SocketState.connected) {
      _reconnectAttempts = 0;
      _clearConnectionTimeoutTimer();
      _startHeartbeat();
      _emitEvent(SocketEvent(type: SocketEventType.connected));
    }
  }

  void _emitEvent(SocketEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

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

  Map<String, dynamic>? _decodeMessage(dynamic message) {
    try {
      if (message is String) {
        final decoded = jsonDecode(message);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        return {'type': 'message', 'content': decoded};
      }

      if (message is Map<String, dynamic>) return message;
      if (message is Map) return Map<String, dynamic>.from(message);
      return {'type': 'message', 'content': message};
    } catch (error) {
      debugLog.socket('MESSAGE_DECODE_ERROR', error: error.toString());
      return {'type': 'message', 'content': message.toString()};
    }
  }

  Future<void> _cleanupActiveSocket({bool keepState = false}) async {
    _clearHeartbeatTimer();
    _clearConnectionTimeoutTimer();

    await _socketSubscription?.cancel();
    _socketSubscription = null;

    try {
      await _channel?.sink.close();
    } catch (error) {
      debugLog.socket('CHANNEL_CLOSE_ERROR', error: error.toString());
    }
    _channel = null;

    if (!keepState && !_manualDisconnect) {
      _setState(SocketState.disconnected);
    }
  }

  Future<void> dispose() async {
    debugLog.socket('DISPOSE');
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    await disconnect();
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    await _eventController.close();
    await _messageController.close();
  }
}
