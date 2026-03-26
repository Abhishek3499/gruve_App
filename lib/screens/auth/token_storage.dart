import 'package:shared_preferences/shared_preferences.dart';

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

    print("💾 ACCESS TOKEN SAVED: $accessToken");
    print("💾 REFRESH TOKEN SAVED: $refreshToken");
  }

  /// ✅ Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);

    print("📤 GET ACCESS TOKEN: $token");

    return token;
  }

  /// ✅ Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_refreshTokenKey);

    print("📤 GET REFRESH TOKEN: $token");

    return token;
  }

  /// ✅ Clear all tokens (logout)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);

    print("🗑️ TOKENS CLEARED");
  }
}
