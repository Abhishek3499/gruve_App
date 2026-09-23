import 'dart:async';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/core/services/socket_service.dart';
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
      AppLogger.debug('TokenRefreshService', 'refresh_already_in_progress');
      return _refreshCompleter!.future;
    }

    // Start new refresh process
    _refreshCompleter = Completer<Map<String, String>?>();

    try {
      AppLogger.debug('TokenRefreshService', 'refresh_started');

      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.warning('TokenRefreshService', 'refresh_token_missing');
        _refreshCompleter!.complete(null);
        return null;
      }

      final baseUrl = EnvironmentConfig.baseUrl.trim();
      if (baseUrl.isEmpty) {
        AppLogger.error('TokenRefreshService', 'base_url_missing');
        _refreshCompleter!.complete(null);
        return null;
      }

      final dio = AuthDio.getInstance();

      AppLogger.debug(
        'TokenRefreshService',
        'api_request',
        data: {'method': 'POST', 'endpoint': ApiConstants.refreshToken},
      );

      final response = await dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken, 'refreshToken': refreshToken},
        options: AuthEndpointPaths.skipAuthOptions(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      AppLogger.debug(
        'TokenRefreshService',
        'api_response',
        data: {
          'method': 'POST',
          'endpoint': ApiConstants.refreshToken,
          'statusCode': response.statusCode,
        },
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

          AppLogger.debug('TokenRefreshService', 'refresh_succeeded');
          _refreshCompleter!.complete({
            'accessToken': newAccessToken,
            'refreshToken': newRefreshToken,
          });

          return {
            'accessToken': newAccessToken,
            'refreshToken': newRefreshToken,
          };
        } else {
          AppLogger.warning('TokenRefreshService', 'invalid_token_response');
          _refreshCompleter!.complete(null);
          return null;
        }
      } else {
        AppLogger.warning(
          'TokenRefreshService',
          'refresh_failed',
          data: {'statusCode': response.statusCode},
        );
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      AppLogger.error('TokenRefreshService', 'refresh_error', error: e);
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
