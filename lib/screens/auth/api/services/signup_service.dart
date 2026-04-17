import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' show debugPrint;
import '../models/signup_request.dart';
import '../models/signup_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignupService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: (dotenv.env['BASE_URL'] ?? "").trim(),
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );

  Future<SignupResponse> signup(SignupRequest request) async {
    if (dio.options.baseUrl.isEmpty) {
      throw "BASE_URL is missing in .env";
    }

    const endpoint = "auth/signup/";
    final payload = request.toJson();

    try {
      debugPrint("=== SIGNUP REQUEST ===");
      debugPrint("URL: ${dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: POST");
      debugPrint("HEADERS: ${dio.options.headers}");
      debugPrint("BODY: $payload");

      final response = await dio.post(endpoint, data: payload);

      debugPrint("=== SIGNUP RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.data}");

      final result = SignupResponse.fromJson(response.data);

      if (result.success == true) {
        return result;
      } else {
        throw result.message;
      }
    } on DioException catch (e) {
      debugPrint("=== SIGNUP DIO ERROR ===");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      debugPrint("ERROR DATA: ${e.response?.data}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("ERROR TYPE: ${e.type}");
      debugPrint("STACK TRACE: ${StackTrace.current}");

      // Retry once when no response is received (timeout / connection issue).
      if (_shouldRetry(e)) {
        try {
          debugPrint("=== SIGNUP RETRY ATTEMPT ===");
          final retryResponse = await dio.post(endpoint, data: payload);
          debugPrint("=== SIGNUP RETRY RESPONSE ===");
          debugPrint("STATUS CODE: ${retryResponse.statusCode}");
          debugPrint("RESPONSE BODY: ${retryResponse.data}");
          final retryResult = SignupResponse.fromJson(retryResponse.data);
          if (retryResult.success == true) return retryResult;
          throw retryResult.message;
        } on DioException catch (retryError) {
          debugPrint("=== SIGNUP RETRY ERROR ===");
          debugPrint("RETRY ERROR: ${retryError.response?.data}");
          debugPrint("RETRY STACK TRACE: ${StackTrace.current}");
          throw _extractErrorMessage(retryError);
        } catch (retryError) {
          debugPrint("=== SIGNUP RETRY UNKNOWN ERROR ===");
          debugPrint("RETRY ERROR: $retryError");
          debugPrint("RETRY STACK TRACE: ${StackTrace.current}");
          throw retryError.toString();
        }
      }

      throw _extractErrorMessage(e);
    } catch (e) {
      debugPrint("=== SIGNUP UNKNOWN ERROR ===");
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: ${StackTrace.current}");
      throw "Signup failed. Please try again.";
    }
  }

  bool _shouldRetry(DioException e) {
    return e.response == null &&
        (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError);
  }

  String _extractErrorMessage(DioException e) {
    final responseData = e.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message = responseData["message"];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final error = responseData["error"];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }

      final errors = responseData["errors"];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.trim().isNotEmpty) return first;
          }
          if (value is String && value.trim().isNotEmpty) return value;
        }
      }
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Request timed out. Please check your internet and try again.";
      case DioExceptionType.connectionError:
        return "Unable to connect. Please check your internet connection.";
      default:
        return "Unable to reach server right now. Please try again.";
    }
  }
}
