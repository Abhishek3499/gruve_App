import 'package:flutter/material.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/auth/current_user_provider.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/api/controllers/logout_controller.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/features/highlights/provider/highlight_flow_provider.dart';
import 'package:gruve_app/features/message/controllers/conversation_controller.dart';
import 'package:gruve_app/features/message/presentation/provider/user_provider.dart';
import 'package:gruve_app/features/message/providers/message_provider.dart';
import 'package:gruve_app/features/notification/providers/notification_provider.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/features/story_preview/providers/drafts_provider.dart';
import 'package:gruve_app/features/story_preview/providers/save_post_provider.dart';
import 'package:gruve_app/features/user_profile/data/controller/user_profile_controller.dart';
import 'package:gruve_app/features/user_profile/providers/block_provider.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class LogoutProvider extends ChangeNotifier {
  final LogoutController _controller = LogoutController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _shouldNavigate = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get shouldNavigate => _shouldNavigate;

  Future<void> logout({BuildContext? context}) async {
    AppLogger.d('[LogoutProvider] Starting logout process');
    _setLoading(true);
    _errorMessage = null;

    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _controller.logout(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        if (_controller.errorMessage != null) {
          AppLogger.d(
            '[LogoutProvider] Logout API returned error: ${_controller.errorMessage}',
          );
        } else {
          AppLogger.d('[LogoutProvider] Logout API completed');
        }
      } else {
        AppLogger.d('[LogoutProvider] No refresh token available for logout API');
      }

      await AuthStateManager().logout();

      if (context != null && context.mounted) {
        final profileProvider = _tryGetProvider<ProfileProvider>(context);
        final storyController = _tryGetProvider<StoryController>(context);
        final highlightProvider = _tryGetProvider<HighlightFlowProvider>(
          context,
        );
        final blockProvider = _tryGetProvider<BlockProvider>(context);
        final saveProvider = _tryGetProvider<SavePostProvider>(context);
        final messageProvider = _tryGetProvider<MessageProvider>(context);
        final conversationController =
            _tryGetProvider<ConversationController>(context);
        final userProvider = _tryGetProvider<UserProvider>(context);
        final notificationProvider =
            _tryGetProvider<NotificationProvider>(context);
        final draftsProvider = _tryGetProvider<DraftsProvider>(context);
        final userProfileController =
            _tryGetProvider<UserProfileController>(context);
        final currentUserProvider = _tryGetProvider<CurrentUserProvider>(context);

        AppLogger.d('[LogoutProvider] Resetting local providers');
        profileProvider?.reset();
        storyController?.reset();
        highlightProvider?.reset();
        blockProvider?.reset();
        saveProvider?.reset();
        messageProvider?.reset();
        conversationController?.reset();
        userProvider?.reset();
        notificationProvider?.reset();
        draftsProvider?.reset();
        userProfileController?.reset();
        currentUserProvider?.clear();
        AppLogger.d('[LogoutProvider] Local providers cleared');
      }

      AppDio.cancelAllRequests('User logout');
      _shouldNavigate = true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.d('[LogoutProvider] Logout exception: $e');

      await AuthStateManager().logout();
      AppDio.cancelAllRequests('User logout fallback');
      _shouldNavigate = true;
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

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void resetNavigationFlag() {
    if (_shouldNavigate) {
      _shouldNavigate = false;
      AppLogger.d('[LogoutProvider] Navigation flag reset');
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      AppLogger.d('[LogoutProvider] Loading: $loading');
      notifyListeners();
    }
  }
}
