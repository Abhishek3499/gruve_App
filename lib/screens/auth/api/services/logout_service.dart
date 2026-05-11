import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import '../models/logout_model.dart';

class LogoutService {
  final Dio dio = AppDio.create(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 8),
    sendTimeout: const Duration(seconds: 5),
  );

  Future<LogoutResponse> logout({
    String? accessToken,
    String? refreshToken,
  }) async {
    final refreshTokenValue =
        refreshToken?.trim().isEmpty ?? true
            ? await TokenStorage.getRefreshToken()
            : refreshToken;
    final accessTokenValue =
        accessToken?.trim().isEmpty ?? true
            ? await TokenStorage.getAccessToken()
            : accessToken;

    if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
      throw "Refresh token not found";
    }

    final request = LogoutRequest(refreshToken: refreshTokenValue);

    try {
      const endpoint = "auth/logout/";
      final requestData = request.toJson();
      final headers = {
        if (accessTokenValue != null && accessTokenValue.isNotEmpty)
          "Authorization": "Bearer $accessTokenValue",
      };
      
      debugPrint("=== LOGOUT REQUEST ===");
      debugPrint("URL: ${dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: POST");
      debugPrint("HEADERS: $headers");
      debugPrint("BODY: $requestData");
      debugPrint("REFRESH TOKEN: $refreshTokenValue");
      debugPrint("ACCESS TOKEN: $accessTokenValue");

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
