import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/auth/current_user_notifier.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/data/services/auth_logger.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/features/auth/presentation/controllers/logout_controller.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_flow_notifier.dart'
    show highlightFlowNotifierProvider;
import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart'
    show subscribeNotifierProvider;
import 'package:gruve_app/features/message/presentation/notifiers/user_notifier.dart'
    show userNotifierProvider;
import 'package:gruve_app/features/message/presentation/notifiers/message_notifier.dart'
    show messageNotifierProvider;
import 'package:gruve_app/features/notification/presentation/notifiers/notification_notifier.dart'
    show notificationNotifierProvider;
import 'package:gruve_app/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:gruve_app/features/share/presentation/notifiers/post_share_notifier.dart'
    show postShareNotifierProvider;
import 'package:gruve_app/features/story_preview/presentation/notifiers/drafts_notifier.dart'
    show draftsNotifierProvider;
import 'package:gruve_app/features/story_preview/presentation/notifiers/post_like_notifier.dart'
    show postLikeNotifierProvider;
import 'package:gruve_app/features/story_preview/presentation/notifiers/save_post_notifier.dart'
    show savePostNotifierProvider;
import 'package:gruve_app/features/story_preview/presentation/notifiers/story_controller_notifier.dart';
import 'package:gruve_app/features/user_profile/presentation/notifiers/block_notifier.dart'
    show blockNotifierProvider;

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

      ref.read(subscribeNotifierProvider).reset();
      ref.read(storyControllerProvider.notifier).reset();
      ref.read(profileNotifierProvider.notifier).reset();

      if (context != null && context.mounted) {
        authLogger.d('[LogoutNotifier] Resetting local providers');
        ref.read(userNotifierProvider.notifier).reset();
        ref.read(currentUserNotifierProvider.notifier).reset();
        ref.read(notificationNotifierProvider.notifier).reset();
        ref.read(messageNotifierProvider.notifier).reset();
        ref.read(postLikeNotifierProvider.notifier).reset();
        ref.read(savePostNotifierProvider.notifier).reset();
        ref.read(draftsNotifierProvider.notifier).reset();
        ref.read(highlightFlowNotifierProvider.notifier).reset();
        ref.read(blockNotifierProvider.notifier).reset();
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
