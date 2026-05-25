import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/services/socket_service.dart';

/// Production-level token refresh service with race condition protection
class TokenRefreshService {
  static final TokenRefreshService _instance = TokenRefreshService._internal();
  factory TokenRefreshService() => _instance;
  TokenRefreshService._internal();

  /// Prevents multiple simultaneous refresh requests
  Completer<Map<String, String>?>? _refreshCompleter;

  /// Queue of pending requests waiting for token refresh
  final List<Completer<void>> _pendingRequests = [];

  /// Whether a refresh is currently in progress
  bool get isRefreshing => _refreshCompleter != null;

  /// Refreshes the access token using the refresh token
  Future<Map<String, String>?> refreshTokens() async {
    // If refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      debugPrint('🔄 [TokenRefresh] Refresh already in progress, waiting...');
      return _refreshCompleter!.future;
    }

    // Start new refresh process
    _refreshCompleter = Completer<Map<String, String>?>();

    try {
      debugPrint('🔄 [TokenRefresh] Starting token refresh...');

      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('❌ [TokenRefresh] No refresh token available');
        _refreshCompleter!.complete(null);
        return null;
      }

      final baseUrl = EnvironmentConfig.baseUrl.trim();
      if (baseUrl.isEmpty) {
        debugPrint('❌ [TokenRefresh] No base URL configured');
        _refreshCompleter!.complete(null);
        return null;
      }

      // Create a fresh Dio instance without interceptors to avoid loops
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      debugPrint('🔄 [TokenRefresh] Sending refresh request to: /auth/refresh');

      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken, 'refreshToken': refreshToken},
        options: AuthEndpointPaths.skipAuthOptions(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      debugPrint(
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

          debugPrint('✅ [TokenRefresh] Tokens refreshed successfully');
          _refreshCompleter!.complete({
            'accessToken': newAccessToken,
            'refreshToken': newRefreshToken,
          });

          return {
            'accessToken': newAccessToken,
            'refreshToken': newRefreshToken,
          };
        } else {
          debugPrint('❌ [TokenRefresh] Invalid token response format');
          _refreshCompleter!.complete(null);
          return null;
        }
      } else {
        debugPrint(
          '❌ [TokenRefresh] Refresh failed with status: ${response.statusCode}',
        );
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      debugPrint('❌ [TokenRefresh] Refresh error: $e');
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      // Clear the completer and process pending requests
      _refreshCompleter = null;
      _processPendingRequests();
    }
  }

  /// Queues a request to wait for token refresh completion
  Future<void> queueRequestUntilRefresh() {
    final completer = Completer<void>();
    _pendingRequests.add(completer);

    // If no refresh is in progress, complete immediately
    if (_refreshCompleter == null) {
      completer.complete();
      _pendingRequests.remove(completer);
    }

    return completer.future;
  }

  /// Processes all pending requests after refresh completes
  void _processPendingRequests() {
    for (final completer in _pendingRequests) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _pendingRequests.clear();
  }

  /// Resets the service state (useful for testing or forced reset)
  void reset() {
    _refreshCompleter = null;
    _pendingRequests.clear();
  }
}
