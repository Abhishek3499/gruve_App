import 'package:dio/dio.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';
import 'package:gruve_app/features/auth/core/auth_api_logger.dart';
import '../models/reset_password_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ResetPasswordService {
  final Dio _dio = AuthDio.getInstance();

  Future<ResetPasswordResponse> resetPassword({
    required String identifier,
    required String otp,
    required String password,
  }) async {
    try {
      const endpoint = ApiConstants.resetPassword;
      final requestData = {
        "identifier": identifier,
        "otp": otp,
        "new_password": password,
      };

      AuthApiLogger.request(
        'ResetPassword',
        dio: _dio,
        endpoint: endpoint,
        method: 'POST',
        body: requestData,
      );

      final response = await _dio.post(
        endpoint,
        data: requestData,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      AuthApiLogger.response('ResetPassword', response);

      return ResetPasswordResponse.fromJson(response.data);
    } on DioException catch (e) {
      AuthApiLogger.error('ResetPassword', e);

      return ResetPasswordResponse(
        message: AuthApiException.extractMessage(e, fallback: 'Server error'),
        success: false,
      );
    } catch (e) {
      AppLogger.d("Reset password failed: $e");

      return ResetPasswordResponse(
        message: "Something went wrong",
        success: false,
      );
    }
  }
}
