import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' show debugPrint;
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/core/auth_api_exception.dart';
import 'package:gruve_app/screens/auth/core/auth_api_logger.dart';
import '../models/signup_request.dart';
import '../models/signup_response.dart';

class SignupService {
  final Dio dio = AppDio.create(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
  );

  Future<SignupResponse> signup(SignupRequest request) async {

    const endpoint = "auth/signup/";
    final payload = request.toJson();

    try {
      AuthApiLogger.request(
        'Signup',
        dio: dio,
        endpoint: endpoint,
        method: 'POST',
        body: payload,
      );

      final response = await dio.post(endpoint, data: payload);

      AuthApiLogger.response('Signup', response);

      final result = SignupResponse.fromJson(response.data);

      if (result.success == true) {
        return result;
      } else {
        throw result.message;
      }
    } on DioException catch (e) {
      AuthApiLogger.error('Signup', e);

      // Retry once when no response is received (timeout / connection issue).
      if (_shouldRetry(e)) {
        try {
          debugPrint("Signup retry attempt");
          final retryResponse = await dio.post(endpoint, data: payload);
          AuthApiLogger.response('SignupRetry', retryResponse);
          final retryResult = SignupResponse.fromJson(retryResponse.data);
          if (retryResult.success == true) return retryResult;
          throw retryResult.message;
        } on DioException catch (retryError) {
          AuthApiLogger.error('SignupRetry', retryError);
          throw AuthApiException.extractMessage(
            retryError,
            fallback: 'Unable to reach server right now. Please try again.',
          );
        } catch (retryError) {
          debugPrint("Signup retry failed: $retryError");
          throw retryError.toString();
        }
      }

      throw AuthApiException.extractMessage(
        e,
        fallback: 'Unable to reach server right now. Please try again.',
      );
    } catch (e) {
      debugPrint("Signup failed: $e");
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

}
