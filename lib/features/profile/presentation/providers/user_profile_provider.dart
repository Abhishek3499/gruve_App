import 'package:flutter/foundation.dart';
import '../../data/services/user_profile_service.dart';
import '../../data/models/user_profile_model.dart';

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

  // Getters
  UserProfileState get state => _state;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == UserProfileState.loading;
  bool get hasError => _state == UserProfileState.error;
  bool get hasData => _state == UserProfileState.loaded && _profile != null;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<void> fetchProfile(String userId) async {
    _log('🔄 [UserProfileProvider] Fetch profile START for userId: $userId');

    // Skip duplicate API call if same userId already loaded
    if (_currentUserId == userId && _state == UserProfileState.loaded && _profile != null) {
      _log('⏭️ [UserProfileProvider] Skipping duplicate fetch for userId: $userId');
      return;
    }

    _currentUserId = userId;
    _state = UserProfileState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _log('🌐 [UserProfileProvider] Calling service for userId: $userId');
      final userProfile = await _service.getUserProfile(userId);
      
      _profile = userProfile;
      _state = UserProfileState.loaded;
      _errorMessage = null;
      
      _log('✅ [UserProfileProvider] Profile loaded successfully: ${userProfile.username}');
      _log('📊 [UserProfileProvider] Stats: ${userProfile.followersCount} followers, ${userProfile.followingCount} following, ${userProfile.postsCount} posts');
    } catch (e) {
      _log('❌ [UserProfileProvider] Error loading profile: $e');
      _state = UserProfileState.error;
      _errorMessage = e.toString();
      _profile = null;
    }

    notifyListeners();
    _log('🏁 [UserProfileProvider] Fetch profile END for userId: $userId');
  }

  void reset() {
    _log('🔄 [UserProfileProvider] Resetting provider state...');
    _state = UserProfileState.idle;
    _profile = null;
    _errorMessage = null;
    _currentUserId = null;
    notifyListeners();
    _log('✅ [UserProfileProvider] Provider reset complete');
  }

  @override
  void dispose() {
    _log('🗑️ [UserProfileProvider] Disposing provider...');
    super.dispose();
  }
}
