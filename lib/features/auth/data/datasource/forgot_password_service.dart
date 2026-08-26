import 'package:dio/dio.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_logger.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ForgotPasswordService {
  final Dio _dio = AuthDio.getInstance();
  Future<String> sendResetLink({required String identifier}) async {
    try {
      const endpoint = ApiConstants.forgotPassword;
      final requestData = {"identifier": identifier};
      
      AuthApiLogger.request(
        'ForgotPassword',
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

      AuthApiLogger.response('ForgotPassword', response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data["message"] ?? "Reset link sent";
      } else {
        throw Exception("Failed to send reset link");
      }
    } on DioException catch (e) {
      AuthApiLogger.error('ForgotPassword', e);

      throw Exception(AuthApiException.extractMessage(e));
    } catch (e) {
      AppLogger.d("Forgot password failed: $e");
      rethrow;
    }
  }
}
