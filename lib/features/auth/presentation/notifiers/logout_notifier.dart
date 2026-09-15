import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:provider/provider.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/auth/current_user_provider.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/data/services/auth_logger.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/features/auth/presentation/controllers/logout_controller.dart';
import 'package:gruve_app/features/highlights/presentation/controller/highlight_flow_provider.dart';
import 'package:gruve_app/features/home/presentation/controllers/subscribe_controller.dart';
import 'package:gruve_app/features/message/presentation/controller/conversation_controller.dart';
import 'package:gruve_app/features/message/presentation/controller/message_provider.dart';
import 'package:gruve_app/features/message/presentation/controller/user_provider.dart';
import 'package:gruve_app/features/notification/presentation/controller/notification_provider.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_provider.dart';
import 'package:gruve_app/features/share/presentation/controller/post_share_provider.dart'
    show postShareNotifierProvider;
import 'package:gruve_app/features/story_preview/presentation/controller/drafts_provider.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/post_like_provider.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/save_post_provider.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/story_controller.dart';
import 'package:gruve_app/features/user_profile/presentation/controller/block_provider.dart';
import 'package:gruve_app/features/user_profile/presentation/controller/user_profile_controller.dart';

/// UI state for the Logout flow: submit-loading flag, the last error (only
/// ever set by an unexpected exception outside the logout API call — an API
/// failure itself is logged but never surfaced here, matching the previous
/// `LogoutProvider` behavior), and a one-shot navigate-to-SignIn flag.
class LogoutUiState {
  const LogoutUiState({
    this.isLoading = false,
    this.errorMessage,
    this.shouldNavigate = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool shouldNavigate;
}

/// Owns Logout's loading/navigation UI state and orchestrates the sign-out
/// sequence, delegating the actual API call to [LogoutController] and
/// session cleanup to [AuthStateManager]. Replaces the previous
/// `LogoutProvider` (ChangeNotifier).
///
/// Local (still Provider-based) feature state is reset via the `context`
/// passed to [logout] — those features have not been migrated to Riverpod
/// yet, so this mirrors exactly what `LogoutProvider` did.
class LogoutNotifier extends Notifier<LogoutUiState> {
  late final LogoutController _controller;

  @override
  LogoutUiState build() {
    _controller = LogoutController();
    return const LogoutUiState();
  }

  Future<void> logout({BuildContext? context}) async {
    authLogger.d('[LogoutNotifier] Starting logout process');
    state = const LogoutUiState(isLoading: true);

    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final result = await _controller.logout(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        if (result.errorMessage != null) {
          authLogger.d(
            '[LogoutNotifier] Logout API returned error: ${result.errorMessage}',
          );
        } else {
          authLogger.d('[LogoutNotifier] Logout API completed');
        }
      } else {
        authLogger.d(
          '[LogoutNotifier] No refresh token available for logout API',
        );
      }

      await AuthStateManager().logout();

      SubscribeController().reset();

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
        final currentUserProvider = _tryGetProvider<CurrentUserProvider>(
          context,
        );
        final postLikeProvider = _tryGetProvider<PostLikeProvider>(context);

        authLogger.d('[LogoutNotifier] Resetting local providers');
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
        postLikeProvider?.reset();
        ref.read(postShareNotifierProvider.notifier).clearSelection();
        authLogger.d('[LogoutNotifier] Local providers cleared');
      }

      AppDio.cancelAllRequests('User logout');
      AuthDio.reset();
      state = const LogoutUiState(isLoading: true, shouldNavigate: true);
    } catch (e) {
      authLogger.d('[LogoutNotifier] Logout exception: $e');

      await AuthStateManager().logout();
      AppDio.cancelAllRequests('User logout fallback');
      AuthDio.reset();
      state = LogoutUiState(
        isLoading: true,
        errorMessage: e.toString(),
        shouldNavigate: true,
      );
    } finally {
      state = LogoutUiState(
        isLoading: false,
        errorMessage: state.errorMessage,
        shouldNavigate: state.shouldNavigate,
      );
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
    if (state.errorMessage != null) {
      state = LogoutUiState(
        isLoading: state.isLoading,
        shouldNavigate: state.shouldNavigate,
      );
    }
  }

  void resetNavigationFlag() {
    if (state.shouldNavigate) {
      authLogger.d('[LogoutNotifier] Navigation flag reset');
      state = LogoutUiState(
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
      );
    }
  }
}

final logoutNotifierProvider = NotifierProvider<LogoutNotifier, LogoutUiState>(
  LogoutNotifier.new,
);
