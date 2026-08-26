import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';
import 'package:gruve_app/features/auth/core/auth_api_logger.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import '../models/logout_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class LogoutService {
  final Dio dio = AppDio.getInstance();

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
      const endpoint = ApiConstants.logout;
      final requestData = request.toJson();
      final headers = {
        if (accessTokenValue != null && accessTokenValue.isNotEmpty)
          "Authorization": "Bearer $accessTokenValue",
      };
      
      AuthApiLogger.request(
        'Logout',
        dio: dio,
        endpoint: endpoint,
        method: 'POST',
        body: {'refresh_token': 'present'},
      );

      final response = await dio.post(
        endpoint,
        data: requestData,
        options: Options(headers: headers),
      );

      AuthApiLogger.response('Logout', response);
      
      return LogoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      AuthApiLogger.error('Logout', e);
      
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
      throw AuthApiException.extractMessage(e, fallback: 'Logout failed');
    } catch (e) {
      AppLogger.d("Logout failed: $e");
      rethrow;
    }
  }
}
