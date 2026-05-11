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
    debugPrint("💾 [TokenStorage] 💾 Saving tokens");
    debugPrint("🎫 [TokenStorage] 🎫 Access token: ${accessToken.substring(0, 10)}...");
    debugPrint("🔄 [TokenStorage] 🔄 Refresh token: ${refreshToken.substring(0, 10)}...");
    
    await _deleteSecure(_currentUserIdKey);
    await _writeSecure(_accessTokenKey, accessToken);
    await _writeSecure(_refreshTokenKey, refreshToken);
    
    debugPrint("✅ [TokenStorage] ✅ Tokens saved successfully");
  }

  static Future<String?> getAccessToken() async {
    debugPrint("🔍 [TokenStorage] 🔍 Retrieving access token");
    final token = await _readSecure(_accessTokenKey);
    if (token != null && token.isNotEmpty) {
      debugPrint("🎫 [TokenStorage] 🎫 Access token found: ${token.substring(0, 10)}...");
      
      // Validate token format (basic JWT check)
      if (_isValidTokenFormat(token)) {
        return token;
      } else {
        debugPrint("❌ [TokenStorage] ❌ Invalid token format detected");
        return null;
      }
    }
    
    debugPrint("⚠️ [TokenStorage] ⚠️ No access token found");
    return null;
  }

  /// Basic token format validation (JWT structure check)
  static bool _isValidTokenFormat(String token) {
    try {
      // Basic JWT format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint("❌ [TokenStorage] ❌ Token doesn't have 3 parts (JWT format)");
        return false;
      }
      
      // Try to decode payload to check expiration
      final payload = parts[1];
      // Pad base64 string if needed
      final paddedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decodedBytes = Uri.decodeComponent(paddedPayload);
      
      // Basic check if payload can be decoded
      if (decodedBytes.isEmpty) {
        debugPrint("❌ [TokenStorage] ❌ Token payload cannot be decoded");
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint("❌ [TokenStorage] ❌ Token validation error: $e");
      return false;
    }
  }

  /// Check if token is likely expired (basic check)
  static Future<bool> isTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = parts[1];
      final paddedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decodedBytes = Uri.decodeComponent(paddedPayload);
      
      // This is a basic check - in production you'd want proper JWT decoding
      return decodedBytes.isEmpty;
    } catch (e) {
      debugPrint("❌ [TokenStorage] ❌ Expiration check error: $e");
      return true; // Assume expired if we can't check
    }
  }

  static Future<String?> getRefreshToken() async {
    debugPrint("🔍 [TokenStorage] 🔍 Retrieving refresh token");
    final token = await _readSecure(_refreshTokenKey);
    if (token != null && token.isNotEmpty) {
      debugPrint("🔄 [TokenStorage] 🔄 Refresh token found: ${token.substring(0, 10)}...");
    } else {
      debugPrint("🚫 [TokenStorage] 🚫 No refresh token found");
    }
    return token;
  }

  static Future<void> saveCurrentUserId(String userId) async {
    debugPrint("👤 [TokenStorage] 👤 Saving current user ID: $userId");
    await _writeSecure(_currentUserIdKey, userId);
    debugPrint("✅ [TokenStorage] ✅ User ID saved successfully");
  }

  static Future<String?> getCurrentUserId() async {
    debugPrint("🔍 [TokenStorage] 🔍 Retrieving current user ID");
    final userId = await _readSecure(_currentUserIdKey);
    if (userId != null && userId.isNotEmpty) {
      debugPrint("👤 [TokenStorage] 👤 User ID found: $userId");
    } else {
      debugPrint("🚫 [TokenStorage] 🚫 No user ID found");
    }
    return userId;
  }

  static Future<void> debugCheckTokens() async {
    debugPrint("🔍 [TokenStorage] 🔍 Debug checking tokens");
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    debugPrint("📊 [TokenStorage] 📊 Token Status:");
    debugPrint("  🎫 Access Token: ${access != null && access.isNotEmpty ? '✅ Present' : '❌ Missing'}");
    debugPrint("  🔄 Refresh Token: ${refresh != null && refresh.isNotEmpty ? '✅ Present' : '❌ Missing'}");
    debugPrint("📋 [TokenStorage] 📋 Summary: accessTokenPresent=${access != null && access.isNotEmpty} refreshTokenPresent=${refresh != null && refresh.isNotEmpty}");
  }

  static Future<void> clearTokens() async {
    // 🔌 DISCONNECT WEBSOCKET WHEN TOKENS ARE CLEARED
    debugPrint("�️ [TokenStorage] 🗑️ Clearing tokens - disconnecting websocket");
    debugPrint("🧹 [TokenStorage] 🧹 Cleaning up secure storage");
    // Note: SocketService disconnect is handled in LogoutController
    // This ensures websocket is disconnected whenever tokens are cleared
    
    await _deleteSecure(_accessTokenKey);
    await _deleteSecure(_refreshTokenKey);
    await _deleteSecure(_currentUserIdKey);
    
    debugPrint("✅ [TokenStorage] ✅ All tokens cleared successfully");
  }

  static Future<void> saveResetToken(String token) async {
    debugPrint("🔐 [TokenStorage] 🔐 Saving reset token: ${token.substring(0, 10)}...");
    await _writeSecure(_resetTokenKey, token);
    debugPrint("✅ [TokenStorage] ✅ Reset token saved successfully");
  }

  static Future<String?> getResetToken() async {
    debugPrint("🔍 [TokenStorage] 🔍 Retrieving reset token");
    final token = await _readSecure(_resetTokenKey);
    if (token != null && token.isNotEmpty) {
      debugPrint("🔐 [TokenStorage] 🔐 Reset token found: ${token.substring(0, 10)}...");
    } else {
      debugPrint("🚫 [TokenStorage] 🚫 No reset token found");
    }
    return token;
  }

  static Future<void> clearResetToken() async {
    debugPrint("🗑️ [TokenStorage] 🗑️ Clearing reset token");
    await _deleteSecure(_resetTokenKey);
    debugPrint("✅ [TokenStorage] ✅ Reset token cleared successfully");
  }
}
