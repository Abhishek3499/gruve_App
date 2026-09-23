import 'package:dio/dio.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/data/services/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/dto/verify_otp_response.dart';
import 'package:gruve_app/features/auth/data/services/auth_logger.dart';

class OtpPurpose {
  static const signup = 'signup';
  static const login = 'login';
  static const resetPassword = 'reset_password';
}

class VerifyOtpService {
  final Dio dio = AuthDio.getInstance();

  Future<VerifyOtpResponse> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  }) async {
    try {
      authLogger.d('Verify OTP purpose=$purpose identifier=$identifier');

      const endpoint = ApiConstants.verifyOtp;
      final body = {'identifier': identifier, 'otp': otp, 'purpose': purpose};

      final response = await dio.post(
        endpoint,
        data: body,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      final result = VerifyOtpResponse.fromJson(response.data);

      if (result.success == true) {
        return result;
      } else {
        throw result.message;
      }
    } on DioException catch (e) {
      throw AuthApiException.extractMessage(e);
    } catch (e) {
      authLogger.d('Verify OTP failed: $e');
      rethrow;
    }
  }

  Future<void> resendOtp({
    required String identifier,
    required String purpose,
  }) async {
    try {
      final body = {'identifier': identifier, 'purpose': purpose};

      final response = await dio.post(
        ApiConstants.resendOtp,
        data: body,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      final isSuccess = response.data?['success'] == true;
      if (!isSuccess) {
        throw response.data?['message']?.toString() ?? 'Failed to resend OTP';
      }
    } on DioException catch (e) {
      throw AuthApiException.extractMessage(e);
    } catch (e) {
      authLogger.d('Resend OTP failed: $e');
      rethrow;
    }
  }
}
