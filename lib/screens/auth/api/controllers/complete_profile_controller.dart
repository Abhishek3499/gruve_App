import 'package:gruve_app/screens/auth/api/services/complete_profile_service.dart';

import '../models/complete_profile_request.dart';
import '../models/complete_profile_response.dart';

class CompleteProfileController {
  final ProfileService _service = ProfileService();
  bool isLoading = false;
  String? errorMessage;
  CompleteProfileResponse? response;

  Future<void> completeProfile({
    required String username,
    String? imagePath,
  }) async {
    isLoading = true;
    errorMessage = null;

    try {
      final result = await _service.completeProfile(
        request: CompleteProfileRequest(username: username),
        imagePath: imagePath,
      );

      response = result;
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
  }
}
