import 'package:dio/dio.dart';
import '../models/signup_request.dart';
import '../models/signup_response.dart';

class SignupService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl:
          "https://6f60-2401-4900-b9ed-d9df-6d2b-4928-c8be-b18d.ngrok-free.app/api/v1/", // 🔥 CHANGE THIS
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<SignupResponse> signup(SignupRequest request) async {
    try {
      final response = await dio.post("auth/signup/", data: request.toJson());

      final result = SignupResponse.fromJson(response.data);

      // 🔥 IMPORTANT LOGIC
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
