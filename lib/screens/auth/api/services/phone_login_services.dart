import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/phone_login_model.dart';

class PhoneSiginServices {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL']!));
  Future<PhoneloginResponse> signIn({required String phone_number}) async {
    try {
      const endpoint = "auth/phone-login/";
      final requestData = {
        "phone_number": phone_number,
      };
      
      debugPrint("=== PHONE LOGIN REQUEST ===");
      debugPrint("URL: ${_dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: POST");
      debugPrint("HEADERS: ${_dio.options.headers}");
      debugPrint("BODY: $requestData");

      final response = await _dio.post(endpoint, data: requestData);

      debugPrint("=== PHONE LOGIN RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.data}");

      return PhoneloginResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("=== PHONE LOGIN DIO ERROR ===");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      debugPrint("ERROR DATA: ${e.response?.data}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("ERROR TYPE: ${e.type}");
      debugPrint("STACK TRACE: ${StackTrace.current}");

      throw e.response?.data["message"] ?? "Something went wrong";
    } catch (e) {
      debugPrint("=== PHONE LOGIN UNKNOWN ERROR ===");
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: ${StackTrace.current}");
      rethrow;
    }
  }
}
