import 'package:dio/dio.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_exception.dart';
import 'package:gruve_app/features/auth/data/datasource/auth_api_logger.dart';
import 'package:gruve_app/features/auth/data/dto/verify_otp_response.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
      AppLogger.d('Verify OTP purpose=$purpose identifier=$identifier');

      const endpoint = ApiConstants.verifyOtp;
      final body = {
        'identifier': identifier,
        'otp': otp,
        'purpose': purpose,
      };

      AuthApiLogger.request(
        'VerifyOtp',
        dio: dio,
        endpoint: endpoint,
        method: 'POST',
        body: body,
      );

      final response = await dio.post(
        endpoint,
        data: body,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      AuthApiLogger.response('VerifyOtp', response);

      final result = VerifyOtpResponse.fromJson(response.data);

      if (result.success == true) {
        return result;
      } else {
        throw result.message;
      }
    } on DioException catch (e) {
      AuthApiLogger.error('VerifyOtp', e);
      throw AuthApiException.extractMessage(e);
    } catch (e) {
      AppLogger.d('Verify OTP failed: $e');
      rethrow;
    }
  }

  Future<void> resendOtp({
    required String identifier,
    required String purpose,
  }) async {
    try {
      final body = {
        'identifier': identifier,
        'purpose': purpose,
      };

      AuthApiLogger.request(
        'ResendOtp',
        dio: dio,
        endpoint: ApiConstants.resendOtp,
        method: 'POST',
        body: body,
      );

      final response = await dio.post(
        ApiConstants.resendOtp,
        data: body,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      AuthApiLogger.response('ResendOtp', response);

      final isSuccess = response.data?['success'] == true;
      if (!isSuccess) {
        throw response.data?['message']?.toString() ?? 'Failed to resend OTP';
      }
    } on DioException catch (e) {
      AuthApiLogger.error('ResendOtp', e);
      throw AuthApiException.extractMessage(e);
    } catch (e) {
      AppLogger.d('Resend OTP failed: $e');
      rethrow;
    }
  }
}
