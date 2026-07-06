import 'dart:async';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/network/auth_dio.dart';

/// Production-level token refresh service with race condition protection
class TokenRefreshService {
  static final TokenRefreshService _instance = TokenRefreshService._internal();
  factory TokenRefreshService() => _instance;
  TokenRefreshService._internal();

  /// Prevents multiple simultaneous refresh requests
  Completer<Map<String, String>?>? _refreshCompleter;



  /// Whether a refresh is currently in progress
  bool get isRefreshing => _refreshCompleter != null;

  /// Refreshes the access token using the refresh token
  Future<Map<String, String>?> refreshTokens() async {
    // If refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      AppLogger.d('🔄 [TokenRefresh] Refresh already in progress, waiting...');
      return _refreshCompleter!.future;
    }

    // Start new refresh process
    _refreshCompleter = Completer<Map<String, String>?>();

    try {
      AppLogger.d('🔄 [TokenRefresh] Starting token refresh...');

      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.d('❌ [TokenRefresh] No refresh token available');
        _refreshCompleter!.complete(null);
        return null;
      }

      final baseUrl = EnvironmentConfig.baseUrl.trim();
      if (baseUrl.isEmpty) {
        AppLogger.d('❌ [TokenRefresh] No base URL configured');
        _refreshCompleter!.complete(null);
        return null;
      }

      final dio = AuthDio.getInstance();

      AppLogger.d('🔄 [TokenRefresh] Sending refresh request to: /auth/refresh');

      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken, 'refreshToken': refreshToken},
        options: AuthEndpointPaths.skipAuthOptions(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      AppLogger.d(
        '📊 [TokenRefresh] Refresh response status: ${response.statusCode}',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final tokenData = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        final newAccessToken =
            tokenData['access_token']?.toString() ??
            tokenData['accessToken']?.toString();
        final newRefreshToken =
            tokenData['refresh_token']?.toString() ??
            tokenData['refreshToken']?.toString();

        if (newAccessToken != null &&
            newAccessToken.isNotEmpty &&
            newRefreshToken != null &&
            newRefreshToken.isNotEmpty) {
          // Save new tokens
          await TokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          await SocketService().reconnectWithLatestTokenIfActive();

          AppLogger.d('✅ [TokenRefresh] Tokens refreshed successfully');
          _refreshCompleter!.complete({
            'accessToken': newAccessToken,
            'refreshToken': newRefreshToken,
          });

          return {
            'accessToken': newAccessToken,
            'refreshToken': newRefreshToken,
          };
        } else {
          AppLogger.d('❌ [TokenRefresh] Invalid token response format');
          _refreshCompleter!.complete(null);
          return null;
        }
      } else {
        AppLogger.d(
          '❌ [TokenRefresh] Refresh failed with status: ${response.statusCode}',
        );
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      AppLogger.d('❌ [TokenRefresh] Refresh error: $e');
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      // Clear the completer
      _refreshCompleter = null;
    }
  }

  /// Resets the service state (useful for testing or forced reset)
  void reset() {
    _refreshCompleter = null;
  }
}
