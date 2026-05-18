import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/api/controllers/logout_controller.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/highlights/provider/highlight_flow_provider.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';

class LogoutProvider extends ChangeNotifier {
  final LogoutController _controller = LogoutController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _shouldNavigate = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get shouldNavigate => _shouldNavigate;

  /// Main logout method with complete state reset
  Future<void> logout({BuildContext? context}) async {
    debugPrint('⚡ [LogoutProvider] ⚡ Starting instant logout process...');
    _setLoading(true);
    _errorMessage = null;

    try {
      // Use auth state manager for centralized logout handling
      await AuthStateManager().logout();

      // Reset local providers if context is available
      if (context != null && context.mounted) {
        final profileProvider = _tryGetProvider<ProfileProvider>(context);
        final storyController = _tryGetProvider<StoryController>(context);
        final highlightProvider = _tryGetProvider<HighlightFlowProvider>(
          context,
        );
        final blockProvider = _tryGetProvider<BlockProvider>(context);
        final saveProvider = _tryGetProvider<SavePostProvider>(context);

        debugPrint('🔄 [LogoutProvider] Resetting local providers...');
        profileProvider?.reset();
        storyController?.reset();
        highlightProvider?.reset();
        blockProvider?.reset();
        saveProvider?.reset();
        debugPrint('✅ [LogoutProvider] Local providers cleared');
      }

      // Cancel pending network requests
      AppDio.cancelAllRequests('User logout');

      // Start logout API in the background after navigation has already been triggered.
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        Future<void>.delayed(Duration.zero, () async {
          try {
            await _controller.logout(
              accessToken: await TokenStorage.getAccessToken(),
              refreshToken: refreshToken,
            );
            if (_controller.errorMessage != null) {
              debugPrint(
                '❌ [LogoutProvider] Background logout API returned error: ${_controller.errorMessage}',
              );
            } else {
              debugPrint('✅ [LogoutProvider] Background logout API completed');
            }
          } catch (e) {
            debugPrint('❌ [LogoutProvider] Background logout API failed: $e');
          }
        });
      } else {
        debugPrint(
          '⚠️ [LogoutProvider] ⚠️ No refresh token available for background logout API',
        );
      }

      _shouldNavigate = true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ [LogoutProvider] Logout exception: $e');
    } finally {
      _setLoading(false);
    }
  }

  T? _tryGetProvider<T>(BuildContext? context) {
    if (context == null) return null;
    try {
      return Provider.of<T>(context, listen: false);
    } catch (_) {
      return null;
    }
  }



  /// Clear any error messages
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Reset navigation flag after navigation is handled
  void resetNavigationFlag() {
    if (_shouldNavigate) {
      _shouldNavigate = false;
      debugPrint('🔄 [LogoutProvider] Navigation flag reset');
      notifyListeners();
    }
  }

  /// Internal method to update loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      debugPrint('🔄 [LogoutProvider] Loading: $loading');
      notifyListeners();
    }
  }
}
