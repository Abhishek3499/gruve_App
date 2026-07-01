import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _resetTokenKey = 'reset_token';
  static const String _currentUserIdKey = 'current_user_id';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Eagerly sync user ID from secure storage to SharedPreferences if not already done
      final syncUserId = _prefs?.getString(_currentUserIdKey);
      if (syncUserId == null) {
        final secureUserId = await _readSecure(_currentUserIdKey);
        if (secureUserId != null && secureUserId.isNotEmpty) {
          await _prefs?.setString(_currentUserIdKey, secureUserId);
          _log('Synced current user ID from secure storage to SharedPreferences: $secureUserId');
        }
      }
    } catch (e) {
      _log('Failed to initialize SharedPreferences in TokenStorage: $e');
    }
  }

  static String? getCurrentUserIdSync() {
    return _prefs?.getString(_currentUserIdKey);
  }

  static void _log(String message) {
    AppLogger.d('[TokenStorage] $message');
  }

  static Future<void> _writeSecure(String key, String value) {
    return _secureStorage.write(key: key, value: value);
  }

  static Future<String?> _readSecure(String key) async {
    final secureValue = await _secureStorage.read(key: key);
    return secureValue == null || secureValue.isEmpty ? null : secureValue;
  }

  static Future<void> _deleteSecure(String key) {
    return _secureStorage.delete(key: key);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _log('Saving tokens');
    await Future.wait<void>([
      _writeSecure(_accessTokenKey, accessToken),
      _writeSecure(_refreshTokenKey, refreshToken),
    ]);
    _log('Tokens saved successfully');
  }

  static Future<String?> getAccessToken() async {
    final token = await _readSecure(_accessTokenKey);
    if (token == null) {
      _log('No access token found');
      return null;
    }

    if (!_isValidTokenFormat(token)) {
      _log('Invalid access token format');
      return null;
    }

    _log('Access token found');
    return token;
  }

  static Future<String?> getRefreshToken() async {
    final token = await _readSecure(_refreshTokenKey);
    _log(token == null ? 'No refresh token found' : 'Refresh token found');
    return token;
  }

  static Future<bool> isTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;

    final exp = _readJwtExp(token);
    if (exp == null) return true;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiresAt);
  }

  static Future<void> saveCurrentUserId(String userId) async {
    _log('Saving current user ID');
    await _writeSecure(_currentUserIdKey, userId);
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(_currentUserIdKey, userId);
    } catch (e) {
      _log('Failed to save current user ID to SharedPreferences: $e');
    }
  }

  static Future<String?> getCurrentUserId() async {
    final userId = await _readSecure(_currentUserIdKey);
    _log(userId == null ? 'No user ID found' : 'User ID found');
    return userId;
  }

  static Future<void> debugCheckTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    _log(
      'accessTokenPresent=${access != null && access.isNotEmpty} '
      'refreshTokenPresent=${refresh != null && refresh.isNotEmpty}',
    );
  }

  static Future<void> clearTokens() async {
    _log('Clearing tokens');
    await _deleteSecure(_accessTokenKey);
    await _deleteSecure(_refreshTokenKey);
    await _deleteSecure(_currentUserIdKey);
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.remove(_currentUserIdKey);
    } catch (e) {
      _log('Failed to clear current user ID from SharedPreferences: $e');
    }
  }

  static Future<void> saveResetToken(String token) async {
    _log('Saving reset token');
    await _writeSecure(_resetTokenKey, token);
  }

  static Future<String?> getResetToken() async {
    final token = await _readSecure(_resetTokenKey);
    _log(token == null ? 'No reset token found' : 'Reset token found');
    return token;
  }

  static Future<void> clearResetToken() async {
    _log('Clearing reset token');
    await _deleteSecure(_resetTokenKey);
  }

  static bool _isValidTokenFormat(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    return _decodeJwtPayload(token) != null;
  }

  static int? _readJwtExp(String token) {
    final payload = _decodeJwtPayload(token);
    final exp = payload?['exp'];
    if (exp is int) return exp;
    if (exp is num) return exp.toInt();
    if (exp is String) return int.tryParse(exp);
    return null;
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final payload = token.split('.')[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map) return Map<String, dynamic>.from(json);
      return null;
    } catch (_) {
      return null;
    }
  }
}
