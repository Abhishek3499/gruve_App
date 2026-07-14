import 'package:flutter/material.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/core/media/video_frame_cache.dart';
import 'package:gruve_app/core/storage/hive_service.dart';
import 'package:gruve_app/features/home/controllers/subscribe_controller.dart';

/// Global authentication state manager
/// Handles token changes, logout flow, and navigation
class AuthStateManager extends ChangeNotifier {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;

  AuthStateManager._internal() {
    // Listen to token changes (this would need platform-specific implementation)
    // For now, we'll rely on explicit calls when tokens are cleared
  }

  bool _isAuthenticated = false;
  bool _isLoggingOut = false;
  String? _currentUserId;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoggingOut => _isLoggingOut;
  String? get currentUserId => _currentUserId;

  Future<String?> getActiveAccessToken() async {
    if (!_isAuthenticated) return null;
    return TokenStorage.getAccessToken();
  }

  /// Initializes auth state by checking stored tokens
  Future<void> initialize() async {
    try {
      // 🚀 EAGER LOAD: Try reading synchronously from SharedPreferences first
      final syncUserId = TokenStorage.getCurrentUserIdSync();
      if (syncUserId != null && syncUserId.isNotEmpty) {
        _currentUserId = syncUserId;
        ProfileIdentityService.instance.primeLoggedInUserId(syncUserId);
        AppLogger.d(
          '🔐 [AuthState] Eagerly loaded userId synchronously: $_currentUserId',
        );
      }

      final accessToken = await TokenStorage.getAccessToken();
      final userId = await TokenStorage.getCurrentUserId();

      final expired = await TokenStorage.isTokenExpired();
      _isAuthenticated =
          accessToken != null && accessToken.isNotEmpty && !expired;

      if (userId != null) {
        _currentUserId = userId;
        ProfileIdentityService.instance.primeLoggedInUserId(userId);
      }

      AppLogger.d(
        '🔐 [AuthState] Initialized - Authenticated: $_isAuthenticated, UserId: $_currentUserId',
      );

      // I-2: Inform the socket layer whether reconnects are permitted at
      // cold start. If _isAuthenticated is false (no stored token / expired),
      // SocketReconnectManager._scheduleReconnect() becomes a no-op so the
      // "missing auth token" reconnect loop cannot start during the login flow.
      SocketService().setAuthState(_isAuthenticated);
    } catch (e) {
      AppLogger.d('🚨 [AuthState] Initialization failed, resetting state: $e');
      _isAuthenticated = false;
      _currentUserId = null;
      ProfileIdentityService.instance.clearCachedLoggedInUserId();
      try {
        await TokenStorage.clearTokens();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _clearSessionScopedState() async {
    SubscribeController().reset();

    final hive = HiveService();
    await hive.clearCache(HiveService.userCacheBoxName);
    await hive.clearCache(HiveService.feedCacheBoxName);
  }

  /// Called when authentication succeeds (login/signup)
  Future<void> onAuthSuccess({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await Future.wait<void>([
      TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
      TokenStorage.saveCurrentUserId(userId),
    ]);

    _isAuthenticated = true;
    _currentUserId = userId;
    _isLoggingOut = false;

    ProfileIdentityService.instance.primeLoggedInUserId(userId);

    await _clearSessionScopedState();

    // I-2: Open the socket reconnect gate BEFORE connect() is called by
    // AuthSessionHelper / SplashScreen so that any failure inside
    // _performConnect can legitimately schedule a reconnect attempt.
    SocketService().setAuthState(true);

    AppLogger.d('✅ [AuthState] Authentication successful for user: $userId');
    notifyListeners();
  }

  /// Called when authentication fails (logout, token refresh failure)
  Future<void> onAuthFailure() async {
    AppLogger.d(
      '🚨 [AuthState] Authentication failed - initiating logout flow',
    );

    _isLoggingOut = true;
    notifyListeners();

    try {
      // Clear all stored data
      await TokenStorage.clearTokens();
      await TokenStorage.clearResetToken();

      ProfileIdentityService.instance.clearCachedLoggedInUserId();

      SubscribeController().reset();
      final hive = HiveService();
      await hive.clearCache(HiveService.userCacheBoxName);
      await hive.clearCache(HiveService.feedCacheBoxName);

      // I-2: Close the socket reconnect gate BEFORE disconnect() so the
      // pending reconnect timer (if any) is cancelled and cannot fire after
      // tokens are wiped.  disconnect() then sets _manualDisconnect = true
      // as a belt-and-suspenders guard.
      SocketService().setAuthState(false);

      // Disconnect socket
      SocketService().disconnect();

      // Clear all caches
      final cacheManager = CacheManager();
      await cacheManager.clear();
      AppLogger.d('✅ [AuthState] All caches cleared');

      // Dispose all cached video controllers
      await VideoFrameCache.disposeAll();
      AppLogger.d('✅ [AuthState] Video frame cache disposed');

      // Reset state
      _isAuthenticated = false;
      _currentUserId = null;

      AppLogger.d('✅ [AuthState] Auth failure cleanup completed');
    } catch (e) {
      AppLogger.d('❌ [AuthState] Error during auth failure cleanup: $e');
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  /// Manually triggers logout (user-initiated)
  Future<void> logout() async {
    AppLogger.d('👋 [AuthState] Manual logout initiated');
    await onAuthFailure();
  }

  /// Checks if user should be redirected to login
  bool shouldRedirectToLogin() {
    return !_isAuthenticated && !_isLoggingOut;
  }

  /// Resets the auth state (useful for testing)
  void reset() {
    _isAuthenticated = false;
    _isLoggingOut = false;
    _currentUserId = null;
    notifyListeners();
  }
}

/// Provider extension for easy access
extension AuthStateProvider on BuildContext {
  AuthStateManager get authState => read<AuthStateManager>();
}
