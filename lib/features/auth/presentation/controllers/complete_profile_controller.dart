import 'package:gruve_app/features/auth/data/services/complete_profile_service.dart';
import 'package:gruve_app/features/auth/data/services/auth_api_exception.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gruve_app/features/auth/data/dto/complete_profile_request.dart';
import 'package:gruve_app/features/auth/data/dto/complete_profile_response.dart';

/// Submits the completed profile (username + photo). Loading state and the
/// selected image are owned by the Complete Profile Riverpod notifier, not
/// here.
class CompleteProfileController {
  CompleteProfileController({CompleteProfileService? service})
      : _service = service ?? CompleteProfileService();

  final CompleteProfileService _service;

  Future<CompleteProfileResult> completeProfile({
    required String username,
    String? file,
    XFile? image,
  }) async {
    try {
      final response = await _service.completeProfile(
        request: CompleteProfileRequest(username: username),
        file: file,
        image: image,
      );

      return CompleteProfileResult.success(response);
    } catch (e) {
      return CompleteProfileResult.failure(
        AuthApiException.userFacingMessage(
          e,
          fallback:
              'Profile could not be saved. Please check your username and photo.',
        ),
      );
    }
  }
}

class CompleteProfileResult {
  const CompleteProfileResult._({
    required this.isSuccess,
    this.response,
    this.errorMessage,
  });

  factory CompleteProfileResult.success(CompleteProfileResponse response) =>
      CompleteProfileResult._(isSuccess: true, response: response);

  factory CompleteProfileResult.failure(String message) =>
      CompleteProfileResult._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final CompleteProfileResponse? response;
  final String? errorMessage;
}
