import 'package:dio/dio.dart';
import 'package:gruve_app/screens/auth/token_storage.dart' show TokenStorage;
import '../models/complete_profile_request.dart';
import '../models/complete_profile_response.dart';

class ProfileService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://YOUR_BASE_URL/api/v1/", // ✅ FIXED BASE URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<CompleteProfileResponse> completeProfile({
    required CompleteProfileRequest request,
    String? imagePath,
  }) async {
    try {
      // 🔥 GET TOKEN
      final token = await TokenStorage.getToken();
      print("USING TOKEN: $token");

      FormData formData = FormData.fromMap({
        "username": request.username,
        if (imagePath != null)
          "profile_image": await MultipartFile.fromFile(imagePath),
      });

      final response = await dio.post(
        "auth/complete-profile/",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token", // 🔥 IMPORTANT
          },
        ),
      );

      final result = CompleteProfileResponse.fromJson(response.data);

      if (result.success == true) {
        return result;
      } else {
        throw result.message;
      }
    } on DioException catch (e) {
      throw e.response?.data["message"] ?? "Something went wrong";
    }
  }
}
