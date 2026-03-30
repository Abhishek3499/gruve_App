import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TokenStorage {
  static const String _accessTokenKey = "access_token";
  static const String _refreshTokenKey = "refresh_token";

  /// ✅ Save both tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);

    debugPrint("💾 ACCESS TOKEN SAVED: $accessToken");
    debugPrint("💾 REFRESH TOKEN SAVED: $refreshToken");
  }

  /// ✅ Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);

    debugPrint("📤 GET ACCESS TOKEN: ${token ?? "EMPTY ❌"}");

    return token;
  }

  /// ✅ Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_refreshTokenKey);

    debugPrint("📤 GET REFRESH TOKEN: ${token ?? "EMPTY ❌"}");

    return token;
  }

  /// 🆕 DEBUG: Check both tokens together
  static Future<void> debugCheckTokens() async {
    final prefs = await SharedPreferences.getInstance();

    final access = prefs.getString(_accessTokenKey);
    final refresh = prefs.getString(_refreshTokenKey);

    debugPrint("========== TOKEN DEBUG ==========");
    debugPrint("Access Token  : ${access ?? "EMPTY ❌"}");
    debugPrint("Refresh Token : ${refresh ?? "EMPTY ❌"}");
    debugPrint("=================================");
  }

  /// ✅ Clear all tokens (logout)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);

    debugPrint("🗑️ TOKENS CLEARED");
  }
}
