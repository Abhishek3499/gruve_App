import 'package:gruve_app/screens/auth/api/services/edit_profile_service.dart';

import '../models/edit_profile_request.dart';
import '../models/edit_profile_response.dart';

class EditProfileController {
  final EditProfileService _service = EditProfileService();
  bool isLoading = false;
  bool isUpdating = false;
  String? errorMessage;
  EditProfileResponse? profileResponse;

  /// Fetch user profile data from API
  Future<void> fetchProfile() async {
    isLoading = true;
    errorMessage = null;
    profileResponse = null;

    try {
      final result = await _service.fetchProfile();
      profileResponse = result;
    } catch (e) {
      profileResponse = null;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    isLoading = false;
  }

  /// Update user profile data
  Future<void> updateProfile({
    required String fullname,
    required String username,
    String? bio,
    // ignore: non_constant_identifier_names
    String? profile_picture,
  }) async {
    isUpdating = true;
    errorMessage = null;
    try {
      final result = await _service.updateProfile(
        request: EditProfileRequest(
          fullname: fullname,
          username: username,
          bio: bio,
          profile_picture: profile_picture,
        ),
      );

      profileResponse = result;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    isUpdating = false;
  }

  /// Check if email should be shown
  bool get showEmail =>
      profileResponse?.data.email != null &&
      profileResponse!.data.email!.isNotEmpty;

  /// Check if phone should be shown
  bool get showPhone =>
      profileResponse?.data.phone != null &&
      profileResponse!.data.phone!.isNotEmpty;

  /// Check if bio should be shown
  bool get showBio =>
      profileResponse?.data.bio != null &&
      profileResponse!.data.bio!.isNotEmpty;

  /// Get current profile picture URL or fallback
  String get currentProfilePicture {
    if (profileResponse?.data.profile_picture != null &&
        profileResponse!.data.profile_picture!.isNotEmpty) {
      return profileResponse!.data.profile_picture!;
    }
    return 'assets/search_screen_images/profile.png'; // Default fallback
  }

  /// Get profile data for form population
  String get username => profileResponse?.data.username ?? '';
  String get fullName => profileResponse?.data.fullName ?? '';
  String get email => profileResponse?.data.email ?? '';
  String get phone => profileResponse?.data.phone ?? '';
  String get gender => profileResponse?.data.gender ?? '';
  String get bio => profileResponse?.data.bio ?? '';

  /// Validate form data
  String? validateForm({
    required String fullName,
    required String username,
    String? bio,
  }) {
    if (fullName.trim().isEmpty) {
      return 'Full name is required';
    }

    if (username.trim().isEmpty) {
      return 'Username is required';
    }

    if (username.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (bio != null && bio.trim().length > 150) {
      return 'Bio must be less than 150 characters';
    }

    return null;
  }

  /// Clear error message
  void clearError() {
    errorMessage = null;
  }
}
