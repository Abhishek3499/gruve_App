import 'package:dio/dio.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/data/services/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/services/auth_logger.dart';

class ForgotPasswordService {
  final Dio _dio = AuthDio.getInstance();
  Future<String> sendResetLink({required String identifier}) async {
    try {
      const endpoint = ApiConstants.forgotPassword;
      final requestData = {"identifier": identifier};

      final response = await _dio.post(
        endpoint,
        data: requestData,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data["message"] ?? "Reset link sent";
      } else {
        throw Exception("Failed to send reset link");
      }
    } on DioException catch (e) {
      throw Exception(AuthApiException.extractMessage(e));
    } catch (e) {
      authLogger.d("Forgot password failed: $e");
      rethrow;
    }
  }
}
