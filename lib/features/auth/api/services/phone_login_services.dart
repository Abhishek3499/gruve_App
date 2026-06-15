import 'package:dio/dio.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';
import 'package:gruve_app/features/auth/core/auth_api_logger.dart';
import '../models/phone_login_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class PhoneSiginServices {
  final Dio _dio = AppDio.getInstance();
  Future<PhoneloginResponse> signIn({required String phoneNumber}) async {
    try {
      const endpoint = "auth/phone-login/";
      final requestData = {"phone_number": phoneNumber};

      AuthApiLogger.request(
        'PhoneLogin',
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

      AuthApiLogger.response('PhoneLogin', response);

      return PhoneloginResponse.fromJson(response.data);
    } on DioException catch (e) {
      AuthApiLogger.error('PhoneLogin', e);

      throw AuthApiException.extractMessage(
        e,
        fallback: 'Please enter a valid phone number.',
      );
    } catch (e) {
      AppLogger.d("Phone login failed: $e");
      rethrow;
    }
  }
}
