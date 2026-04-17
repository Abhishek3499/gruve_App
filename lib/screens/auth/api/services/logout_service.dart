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
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 5),
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
      const endpoint = "auth/logout/";
      final requestData = request.toJson();
      final headers = {
        if (accessToken != null && accessToken.isNotEmpty)
          "Authorization": "Bearer $accessToken",
      };
      
      debugPrint("=== LOGOUT REQUEST ===");
      debugPrint("URL: ${dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: POST");
      debugPrint("HEADERS: $headers");
      debugPrint("BODY: $requestData");
      debugPrint("REFRESH TOKEN: $refreshToken");
      debugPrint("ACCESS TOKEN: $accessToken");

      final response = await dio.post(
        endpoint,
        data: requestData,
        options: Options(headers: headers),
      );

      debugPrint("=== LOGOUT RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.data}");
      
      return LogoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("=== LOGOUT DIO ERROR ===");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      debugPrint("ERROR DATA: ${e.response?.data}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("ERROR TYPE: ${e.type}");
      debugPrint("STACK TRACE: ${StackTrace.current}");
      
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
    } catch (e) {
      debugPrint("=== LOGOUT UNKNOWN ERROR ===");
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: ${StackTrace.current}");
      rethrow;
    }
  }
}
