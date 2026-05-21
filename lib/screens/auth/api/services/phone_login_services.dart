import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/core/auth_api_exception.dart';
import 'package:gruve_app/screens/auth/core/auth_api_logger.dart';
import '../models/phone_login_model.dart';

class PhoneSiginServices {
  final Dio _dio = AppDio.create();
  Future<PhoneloginResponse> signIn({required String phoneNumber}) async {
    try {
      const endpoint = "auth/phone-login/";
      final requestData = {
        "phone_number": phoneNumber,
      };
      
      AuthApiLogger.request(
        'PhoneLogin',
        dio: _dio,
        endpoint: endpoint,
        method: 'POST',
        body: requestData,
      );

      final response = await _dio.post(endpoint, data: requestData);

      AuthApiLogger.response('PhoneLogin', response);

      return PhoneloginResponse.fromJson(response.data);
    } on DioException catch (e) {
      AuthApiLogger.error('PhoneLogin', e);

      throw AuthApiException.extractMessage(e);
    } catch (e) {
      debugPrint("Phone login failed: $e");
      rethrow;
    }
  }
}
