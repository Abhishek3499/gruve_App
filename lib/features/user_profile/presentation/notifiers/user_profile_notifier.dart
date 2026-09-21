import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/user_profile/data/datasource/user_profile_service.dart';
import 'package:gruve_app/features/user_profile/domain/entities/user_profile_model.dart';

enum UserProfileState { idle, loading, loaded, error }

@immutable
class UserProfileUiState {
  const UserProfileUiState({
    this.state = UserProfileState.idle,
    this.profile,
    this.errorMessage,
    this.currentUserId,
  });

  final UserProfileState state;
  final UserProfile? profile;
  final String? errorMessage;
  final String? currentUserId;

  bool get isLoading => state == UserProfileState.loading;
  bool get hasError => state == UserProfileState.error;
  bool get hasData => state == UserProfileState.loaded && profile != null;

  UserProfileUiState copyWith({
    UserProfileState? state,
    UserProfile? profile,
    String? errorMessage,
    String? currentUserId,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return UserProfileUiState(
      state: state ?? this.state,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfileUiState> {
  UserProfileNotifier({UserProfileService? service})
    : _service = service ?? UserProfileService();

  final UserProfileService _service;
  CancelToken? _cancelToken;
  final Map<String, Future<void>> _inFlightFetches = {};

  @override
  UserProfileUiState build() {
    ref.onDispose(() {
      cancelActiveRequests();
      AppLogger.d('🗑️ [UserProfileNotifier] Disposing notifier...');
    });
    return const UserProfileUiState();
  }

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Profile screen disposed');
    _cancelToken = null;
  }

  void _log(String message) {
    AppLogger.d(message);
  }

  UserProfileState get currentState => state.state;
  UserProfile? get profile => state.profile;
  String? get errorMessage => state.errorMessage;
  bool get isLoading => state.isLoading;
  bool get hasError => state.hasError;
  bool get hasData => state.hasData;

  Future<void> fetchProfile(String userId, {bool silent = false}) async {
    _log('🔄 [UserProfileNotifier] Fetch profile START for userId: $userId');

    // Skip duplicate API call if same userId already loaded
    if (state.currentUserId == userId &&
        state.state == UserProfileState.loaded &&
        state.profile != null) {
      _log(
        '⏭️ [UserProfileNotifier] Skipping duplicate fetch for userId: $userId',
      );
      return;
    }

    final inFlight = _inFlightFetches[userId];
    if (inFlight != null) {
      _log(
        '⏳ [UserProfileNotifier] Joining in-flight fetch for userId: $userId',
      );
      return inFlight;
    }

    final future = _runFetchProfile(userId, silent: silent);
    _inFlightFetches[userId] = future;
    try {
      return await future;
    } finally {
      _inFlightFetches.remove(userId);
    }
  }

  Future<void> _runFetchProfile(String userId, {required bool silent}) async {
    if (!silent) {
      state = state.copyWith(
        currentUserId: userId,
        state: UserProfileState.loading,
        clearError: true,
      );
    } else {
      state = state.copyWith(currentUserId: userId);
    }

    try {
      _log('🌐 [UserProfileNotifier] Calling service for userId: $userId');
      final userProfile = await _service
          .getUserProfileModel(userId, cancelToken: _getCancelToken())
          .timeout(const Duration(seconds: 20));
      if (state.currentUserId != userId) {
        _log(
          '⏭️ [UserProfileNotifier] Stale profile response ignored: $userId',
        );
        return;
      }

      state = state.copyWith(
        profile: userProfile,
        state: UserProfileState.loaded,
        clearError: true,
      );

      _log(
        '✅ [UserProfileNotifier] Profile loaded successfully: ${userProfile.username}',
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('[UserProfileNotifier] fetchProfile cancelled');
        return;
      }
      _log('❌ [UserProfileNotifier] Error loading profile: $e');
      state = state.copyWith(
        state: UserProfileState.error,
        errorMessage: e.toString(),
        clearProfile: true,
      );
    } finally {
      _log('🏁 [UserProfileNotifier] Fetch profile END for userId: $userId');
    }
  }

  void reset() {
    _log('🔄 [UserProfileNotifier] Resetting notifier state...');
    state = const UserProfileUiState();
    _inFlightFetches.clear();
    _log('✅ [UserProfileNotifier] Notifier reset complete');
  }
}

final userProfileNotifierProvider =
    NotifierProvider<UserProfileNotifier, UserProfileUiState>(
      UserProfileNotifier.new,
    );
