import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:gruve_app/features/user_profile/data/datasource/user_profile_service.dart';
import 'package:gruve_app/features/profile/domain/entities/user_profile_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

enum UserProfileState {
  idle,
  loading,
  loaded,
  error,
}

class UserProfileProvider extends ChangeNotifier {
  final UserProfileService _service;

  UserProfileProvider({UserProfileService? service})
      : _service = service ?? UserProfileService();

  UserProfileState _state = UserProfileState.idle;
  UserProfile? _profile;
  String? _errorMessage;
  String? _currentUserId;
  CancelToken? _cancelToken;

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Profile screen disposed');
    _cancelToken = null;
  }

  final Map<String, Future<void>> _inFlightFetches = {};

  // Getters
  UserProfileState get state => _state;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == UserProfileState.loading;
  bool get hasError => _state == UserProfileState.error;
  bool get hasData => _state == UserProfileState.loaded && _profile != null;

  void _log(String message) {
    AppLogger.d(message);
    
  }

  Future<void> fetchProfile(String userId, {bool silent = false}) async {
    _log('🔄 [UserProfileProvider] Fetch profile START for userId: $userId');

    // Skip duplicate API call if same userId already loaded
    if (_currentUserId == userId && _state == UserProfileState.loaded && _profile != null) {
      _log('⏭️ [UserProfileProvider] Skipping duplicate fetch for userId: $userId');
      return;
    }

    final inFlight = _inFlightFetches[userId];
    if (inFlight != null) {
      _log('⏳ [UserProfileProvider] Joining in-flight fetch for userId: $userId');
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
    _currentUserId = userId;
    _state = UserProfileState.loading;
    _errorMessage = null;
    
    // Only notify if not silent (prevents build-time notifications)
    if (!silent) notifyListeners();

    try {
      _log('🌐 [UserProfileProvider] Calling service for userId: $userId');
      final userProfile = await _service
          .getUserProfileModel(userId, cancelToken: _getCancelToken())
          .timeout(const Duration(seconds: 20));
      if (_currentUserId != userId) {
        _log('⏭️ [UserProfileProvider] Stale profile response ignored: $userId');
        return;
      }
      
      _profile = userProfile;
      _state = UserProfileState.loaded;
      _errorMessage = null;
      
      _log('✅ [UserProfileProvider] Profile loaded successfully: ${userProfile.username}');
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('[UserProfileProvider] fetchProfile cancelled');
        return;
      }
      _log('❌ [UserProfileProvider] Error loading profile: $e');
      _state = UserProfileState.error;
      _errorMessage = e.toString();
      _profile = null;
    } finally {
      notifyListeners();
      _log('🏁 [UserProfileProvider] Fetch profile END for userId: $userId');
    }
  }

  void reset() {
    _log('🔄 [UserProfileProvider] Resetting provider state...');
    _state = UserProfileState.idle;
    _profile = null;
    _errorMessage = null;
    _currentUserId = null;
    _inFlightFetches.clear();
    notifyListeners();
    _log('✅ [UserProfileProvider] Provider reset complete');
  }

  @override
  void dispose() {
    cancelActiveRequests();
    _log('🗑️ [UserProfileProvider] Disposing provider...');
    super.dispose();
  }
}
