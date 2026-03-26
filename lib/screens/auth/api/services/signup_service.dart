import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' show debugPrint;
import '../models/signup_request.dart';
import '../models/signup_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignupService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL']!, // 🔥 CHANGE THIS
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
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      debugPrint("FULL ERROR: ${e.response?.data}");

      throw e.response?.data.toString() ?? "Something went wrong";
    }
  }
}
