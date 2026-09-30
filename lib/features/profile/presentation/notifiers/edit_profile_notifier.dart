import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/auth/validators/signup_validator.dart';
import 'package:gruve_app/features/profile/data/datasource/edit_profile_service.dart';
import 'package:gruve_app/features/profile/data/dto/edit_profile_request.dart';
import 'package:gruve_app/features/profile/data/dto/edit_profile_response.dart';

@immutable
class EditProfileState {
  const EditProfileState({
    this.isLoading = false,
    this.isUpdating = false,
    this.errorMessage,
    this.profileResponse,
  });

  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;
  final EditProfileResponse? profileResponse;

  bool get showEmail =>
      profileResponse?.data.email != null &&
      profileResponse!.data.email!.isNotEmpty;

  bool get showPhone =>
      profileResponse?.data.phone != null &&
      profileResponse!.data.phone!.isNotEmpty;

  String get currentProfilePicture {
    final picture = profileResponse?.data.profilePicture;
    if (picture != null && picture.isNotEmpty) return picture;
    return 'assets/search_screen_images/profile.png';
  }

  String get username => profileResponse?.data.username ?? '';
  String get fullName => profileResponse?.data.fullName ?? '';
  String get email => profileResponse?.data.email ?? '';
  String get phone => profileResponse?.data.phone ?? '';
  String get gender => profileResponse?.data.gender ?? '';
  String get bio => profileResponse?.data.bio ?? '';

  EditProfileState copyWith({
    bool? isLoading,
    bool? isUpdating,
    String? errorMessage,
    EditProfileResponse? profileResponse,
    bool clearError = false,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      profileResponse: profileResponse ?? this.profileResponse,
    );
  }
}

class EditProfileNotifier extends Notifier<EditProfileState> {
  final EditProfileService _service = EditProfileService();

  @override
  EditProfileState build() => const EditProfileState();

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _service.fetchProfile();
      state = state.copyWith(profileResponse: result, clearError: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateProfile({
    required String fullname,
    required String username,
    String? bio,
    String? profilePicture,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    final trimmedBio = bio?.trim();
    final cleanBio = (trimmedBio != null && trimmedBio.isNotEmpty) ? trimmedBio : null;

    try {
      final result = await _service.updateProfile(
        request: EditProfileRequest(
          fullname: fullname.trim(),
          username: username.trim(),
          bio: cleanBio,
          profilePicture: profilePicture,
        ),
      );
      state = state.copyWith(profileResponse: result, clearError: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      state = state.copyWith(isUpdating: false);
    }
  }

  String? validateForm({
    required String fullName,
    required String username,
    String? bio,
  }) {
    final nameError = SignupValidator.validateFullNameRealTime(fullName);
    if (nameError != null) return nameError;

    final usernameError = SignupValidator.validateUsernameRealTime(username);
    if (usernameError != null) return usernameError;

    if (bio != null && bio.trim().length > 150) {
      return "Bio must be 150 characters or less.";
    }

    return null;
  }
}

final editProfileNotifierProvider =
    NotifierProvider<EditProfileNotifier, EditProfileState>(
      EditProfileNotifier.new,
    );
