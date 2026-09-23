import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Centralized WebSocket/Socket event logger.
///
/// Emits exactly one compact JSON object per socket event, matching
/// the format used by [ApiLogger]. Only active in debug builds; sensitive
/// fields are masked before printing.
class SocketLogger {
  SocketLogger._();

  // Compact (single-line) JSON, matching AppLogger's console format.
  static const JsonEncoder _encoder = JsonEncoder();

  static const Set<String> _sensitiveKeys = {
    'password',
    'confirmpassword',
    'otp',
    'accesstoken',
    'refreshtoken',
    'resettoken',
    'authorization',
    'cookie',
    'clientsecret',
    'secret',
    'apikey',
    'token',
  };

  static void connect(String url) {
    _log('CONNECT', {'url': url, 'status': 'connecting'});
  }

  static void connected(String url) {
    _log('CONNECT', {'url': url, 'status': 'connected'});
  }

  static void disconnect({String? reason}) {
    _log('DISCONNECT', {'status': 'disconnected', 'reason': reason});
  }

  static void reconnecting(int attempt) {
    _log('RECONNECT', {'attempt': attempt, 'status': 'attempting'});
  }

  static void reconnectSuccess(int attempt) {
    _log('RECONNECT_SUCCESS', {'attempt': attempt, 'status': 'connected'});
  }

  static void reconnectError(int attempt, String error) {
    _log('RECONNECT_ERROR', {'attempt': attempt, 'error': error});
  }

  static void send(dynamic data) {
    _log('SEND', {'data': _mask(data)});
  }

  static void receive(dynamic data) {
    _log('RECEIVE', {'data': _mask(data)});
  }

  static void error(String message) {
    _log('ERROR', {
      'error': {'message': message},
    });
  }

  static void heartbeat(dynamic data) {
    _log('HEARTBEAT', {'data': _mask(data)});
  }

  static dynamic _mask(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, v) {
        final keyString = key.toString();
        result[keyString] = _isSensitiveKey(keyString) ? '***' : _mask(v);
      });
      return result;
    }
    if (value is Iterable) {
      return value.map(_mask).toList();
    }
    return value;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    return _sensitiveKeys.any((sensitive) => normalized.contains(sensitive));
  }

  static void _log(String event, Map<String, dynamic> fields) {
    if (!kDebugMode) return;

    try {
      final entry = <String, dynamic>{
        'type': 'SOCKET',
        'event': event,
        ...fields,
      };
      final pretty = _encoder.convert(entry);
      for (final line in pretty.split('\n')) {
        debugPrint(line);
      }
    } catch (_) {
      debugPrint('{"type":"SOCKET","error":{"message":"log encoding failed"}}');
    }
  }
}
