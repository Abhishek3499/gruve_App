import 'package:flutter/material.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:provider/provider.dart';

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

  /// Initializes auth state by checking stored tokens
  Future<void> initialize() async {
    final accessToken = await TokenStorage.getAccessToken();
    final userId = await TokenStorage.getCurrentUserId();

    _isAuthenticated = accessToken != null && accessToken.isNotEmpty;
    _currentUserId = userId;

    debugPrint(
      '🔐 [AuthState] Initialized - Authenticated: $_isAuthenticated, UserId: $_currentUserId',
    );
    notifyListeners();
  }

  /// Called when authentication succeeds (login/signup)
  Future<void> onAuthSuccess({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await TokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await TokenStorage.saveCurrentUserId(userId);

    _isAuthenticated = true;
    _currentUserId = userId;
    _isLoggingOut = false;

    debugPrint('✅ [AuthState] Authentication successful for user: $userId');
    notifyListeners();
  }

  /// Called when authentication fails (logout, token refresh failure)
  Future<void> onAuthFailure() async {
    debugPrint('🚨 [AuthState] Authentication failed - initiating logout flow');

    _isLoggingOut = true;
    notifyListeners();

    try {
      // Clear all stored data
      await TokenStorage.clearTokens();
      await TokenStorage.clearResetToken();

      // Disconnect socket
      SocketService().disconnect();

      // Clear all caches
      final cacheManager = CacheManager();
      await cacheManager.clear();
      debugPrint('✅ [AuthState] All caches cleared');

      // Reset state
      _isAuthenticated = false;
      _currentUserId = null;

      debugPrint('✅ [AuthState] Auth failure cleanup completed');
    } catch (e) {
      debugPrint('❌ [AuthState] Error during auth failure cleanup: $e');
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  /// Manually triggers logout (user-initiated)
  Future<void> logout() async {
    debugPrint('👋 [AuthState] Manual logout initiated');
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
