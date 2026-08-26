import 'package:gruve_app/features/auth/data/datasource/complete_profile_service.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gruve_app/features/auth/data/dto/complete_profile_request.dart';
import 'package:gruve_app/features/auth/data/dto/complete_profile_response.dart';

class CompleteProfileController {
  final CompleteProfileService _service = CompleteProfileService();
  bool isLoading = false;
  String? errorMessage;
  CompleteProfileResponse? response;

  Future<void> completeProfile({
    required String username,
    String? file,
    XFile? image,
  }) async {
    isLoading = true;
    errorMessage = null;
    response = null;

    try {
      final result = await _service.completeProfile(
        request: CompleteProfileRequest(username: username),
        file: file,
        image: image,
      );

      response = result;
    } catch (e) {
      response = null;
      errorMessage = AuthApiException.userFacingMessage(
        e,
        fallback:
            'Profile could not be saved. Please check your username and photo.',
      );
    } finally {
      isLoading = false;
    }
  }
}
