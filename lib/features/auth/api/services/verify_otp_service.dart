import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';
import 'package:gruve_app/features/auth/core/auth_api_logger.dart';
import '../models/verify_otp_response.dart';

class VerifyOtpService {
  final Dio dio = AppDio.create(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
  Future<VerifyOtpResponse> verifyOtp({
    required String identifier,
    required String email,
    required String phoneNumber,
    required String type,
    required String otp,
    bool isLogin = false,
    bool isForgot = false, // ✅ ADD THIS
  }) async {
    try {
      debugPrint(
        "Verify OTP flow: forgot=$isForgot login=$isLogin type=$type",
      );

      Map<String, dynamic> body;
      String endpoint;

      // Decide endpoint
      if (isForgot) {
        endpoint = "auth/password-reset/verify-otp/";
        body = {"email": email, "otp": otp};
      } else if (isLogin) {
        endpoint = "auth/verify-phone-login-otp/";
        body = {"phone_number": phoneNumber, "otp": otp};
      } else {
        endpoint = "auth/verify-otp/";

        // Signup (email OR phone)
        if (type == "phone") {
          body = {"identifier": identifier, "otp": otp};
        } else {
          body = {"identifier": identifier, "otp": otp};
        }
      }

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
      debugPrint("Verify OTP failed: $e");
      rethrow;
    }
  }

  Future<void> resendOtp({
    required String identifier,
    required String purpose,
  }) async {
    try {
      final body = {
        "identifier": identifier,
        "purpose": purpose,
      };

      AuthApiLogger.request(
        'ResendOtp',
        dio: dio,
        endpoint: 'auth/resend-otp/',
        method: 'POST',
        body: body,
      );

      final response = await dio.post(
        'auth/resend-otp/',
        data: body,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      AuthApiLogger.response('ResendOtp', response);

      final isSuccess = response.data?['success'] == true;
      if (!isSuccess) {
        throw response.data?['message']?.toString() ?? "Failed to resend OTP";
      }
    } on DioException catch (e) {
      AuthApiLogger.error('ResendOtp', e);
      throw AuthApiException.extractMessage(e);
    } catch (e) {
      debugPrint("Resend OTP failed: $e");
      rethrow;
    }
  }
}
