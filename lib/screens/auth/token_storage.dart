import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const String _accessTokenKey = "access_token";
  static const String _refreshTokenKey = "refresh_token";
  static const String _resetTokenKey = "reset_token";
  static const String _currentUserIdKey = "current_user_id";

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> _writeSecure(String key, String value) {
    return _secureStorage.write(key: key, value: value);
  }

  static Future<String?> _readSecure(String key) async {
    final secureValue = await _secureStorage.read(key: key);
    if (secureValue != null && secureValue.isNotEmpty) {
      return secureValue;
    }

    return null;
  }

  static Future<void> _deleteSecure(String key) {
    return _secureStorage.delete(key: key);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _deleteSecure(_currentUserIdKey);
    await _writeSecure(_accessTokenKey, accessToken);
    await _writeSecure(_refreshTokenKey, refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return _readSecure(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return _readSecure(_refreshTokenKey);
  }

  static Future<void> saveCurrentUserId(String userId) async {
    await _writeSecure(_currentUserIdKey, userId);
  }

  static Future<String?> getCurrentUserId() async {
    return _readSecure(_currentUserIdKey);
  }

  static Future<void> debugCheckTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    debugPrint(
      "[TokenStorage] accessTokenPresent=${access != null && access.isNotEmpty} refreshTokenPresent=${refresh != null && refresh.isNotEmpty}",
    );
  }

  static Future<void> clearTokens() async {
    await _deleteSecure(_accessTokenKey);
    await _deleteSecure(_refreshTokenKey);
    await _deleteSecure(_currentUserIdKey);
  }

  static Future<void> saveResetToken(String token) async {
    await _writeSecure(_resetTokenKey, token);
  }

  static Future<String?> getResetToken() async {
    return _readSecure(_resetTokenKey);
  }

  static Future<void> clearResetToken() async {
    await _deleteSecure(_resetTokenKey);
  }
}
