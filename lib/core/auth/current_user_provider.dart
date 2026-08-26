import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/data/datasource/profile_services.dart';
import 'package:gruve_app/features/profile/domain/entities/profile_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Provides current user's profile data including profile image
class CurrentUserProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  
  String? _profileImageUrl;
  String? _username;
  int _unreadNotificationCount = 0;
  bool _isLoading = false;
  
  String? get profileImageUrl => _profileImageUrl;
  String? get username => _username;
  int get unreadNotificationCount => _unreadNotificationCount;
  bool get isLoading => _isLoading;
  
  /// Fetches current user's profile data
  Future<void> fetchCurrentUserProfile() async {
    if (_isLoading) return;
    if (_profileImageUrl != null && _profileImageUrl!.trim().isNotEmpty) {
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      AppLogger.d('🔄 [CurrentUserProvider] Fetching user profile...');
      final profileData = await _profileService.getUser();
      
      AppLogger.d('🔍 [CurrentUserProvider] Profile data keys: ${profileData.keys.toList()}');
      
      // Extract profile image URL and username securely using ProfileModel parsing
      final parsedProfile = ProfileModel.fromJson(profileData);
      _profileImageUrl = parsedProfile.profileImage;
      _username = parsedProfile.username;
      _unreadNotificationCount = parsedProfile.unreadNotificationCount;
      
      AppLogger.d('✅ [CurrentUserProvider] Profile fetched - Image: $_profileImageUrl');
      AppLogger.d('✅ [CurrentUserProvider] Username: $_username');
      AppLogger.d('✅ [CurrentUserProvider] Unread Notifications Count: $_unreadNotificationCount');
    } catch (e) {
      AppLogger.d('❌ [CurrentUserProvider] Failed to fetch profile: $e');
      _profileImageUrl = null;
      _username = null;
      _unreadNotificationCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Clears profile data (call on logout)
  void clear() {
    _profileImageUrl = null;
    _username = null;
    _unreadNotificationCount = 0;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Updates profile image URL (call after profile update)
  void updateProfileImage(String? imageUrl) {
    _profileImageUrl = imageUrl;
    notifyListeners();
  }

  /// Updates profile data (call after profile update)
  void updateProfileData({String? username, String? imageUrl}) {
    if (username != null) _username = username;
    if (imageUrl != null) _profileImageUrl = imageUrl;
    notifyListeners();
  }
}
