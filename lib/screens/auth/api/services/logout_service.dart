import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import '../models/logout_model.dart';

class LogoutService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL']!,
      headers: {"Content-Type": "application/json"},
    ),
  );

  Future<LogoutResponse> logout() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    final accessToken = await TokenStorage.getAccessToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw "Refresh token not found";
    }

    final request = LogoutRequest(refreshToken: refreshToken);

    try {
      final response = await dio.post(
        "auth/logout/",
        data: request.toJson(),
        options: Options(
          headers: {
            if (accessToken != null && accessToken.isNotEmpty)
              "Authorization": "Bearer $accessToken",
          },
        ),
      );

      debugPrint("🔥 LOGOUT RESPONSE: ${response.data}");
      return LogoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("❌ LOGOUT API ERROR: ${e.response?.data}");
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData["message"] != null) {
          throw responseData["message"].toString();
        }
        if (responseData["detail"] != null) {
          throw responseData["detail"].toString();
        }
        if (responseData["refresh_token"] != null) {
          throw responseData["refresh_token"].toString();
        }
      }
      throw "Logout failed";
    }
  }
}
