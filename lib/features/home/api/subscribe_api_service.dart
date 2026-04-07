import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class SubscribeApiService {
  late final Dio _dio;

  SubscribeApiService() {
    var base = dotenv.env['BASE_URL']!.trim();
    if (!base.endsWith('/')) {
      base = '$base/';
    }
    _dio = Dio(BaseOptions(baseUrl: base));
  }

  /// Toggle subscription (subscribe/unsubscribe)
  /// POST /user/subscribe/toggle/
  /// Response: {"success": true, "is_subscribed": true/false} or error
  Future<bool> toggleSubscription(String userId) async {
    try {
      print(" TOGGLE SUBSCRIBE API CALL START");
      print("USER ID: $userId");

      final token = await TokenStorage.getAccessToken();

      final response = await _dio.post(
        "user/subscribe/toggle/",
        data: {"user_id": userId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("SUBSCRIBE API RESPONSE: ${response.data}");
      print("STATUS CODE: ${response.statusCode}");

      final isSubscribed = response.data['data']?['is_subscribed'] ?? false;
      print("SUBSCRIPTION STATUS: $isSubscribed");

      return isSubscribed;
    } catch (e) {
      print("SUBSCRIBE API ERROR: $e");
      if (e is DioException) {
        print("STATUS CODE: ${e.response?.statusCode}");
        print("RESPONSE DATA: ${e.response?.data}");
        print("ERROR MESSAGE: ${e.message}");

        // Handle specific error cases
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 400 &&
            responseData?['message']?.toString().contains(
                  'subscribe to yourself',
                ) ==
                true) {
          print("USER TRIED TO SUBSCRIBE TO THEMSELVES");
          throw Exception("You cannot subscribe to yourself");
        }
      }
      rethrow;
    }
  }

  /// Subscribe to user
  Future<bool> subscribeToUser(String userId) async {
    try {
      print("SUBSCRIBE API CALL START");
      print("USER ID: $userId");

      final token = await TokenStorage.getAccessToken();

      final response = await _dio.post(
        "posts/get-post/",
        data: {"user_id": userId, "action": "subscribe"},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("SUBSCRIBE API RESPONSE: ${response.data}");
      print("STATUS CODE: ${response.statusCode}");

      final isSubscribed = response.data['is_subscribed'] ?? false;
      print("SUBSCRIPTION STATUS: $isSubscribed");

      return isSubscribed;
    } catch (e) {
      print("SUBSCRIBE API ERROR: $e");
      if (e is DioException) {
        print("STATUS CODE: ${e.response?.statusCode}");
        print("RESPONSE DATA: ${e.response?.data}");
        print("ERROR MESSAGE: ${e.message}");
      }
      rethrow;
    }
  }

  /// Unsubscribe from user
  Future<bool> unsubscribeFromUser(String userId) async {
    try {
      print("UNSUBSCRIBE API CALL START");
      print("USER ID: $userId");

      final token = await TokenStorage.getAccessToken();

      final response = await _dio.post(
        "posts/get-post/",
        data: {"user_id": userId, "action": "unsubscribe"},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("UNSUBSCRIBE API RESPONSE: ${response.data}");
      print("STATUS CODE: ${response.statusCode}");

      final isSubscribed = response.data['is_subscribed'] ?? false;
      print("SUBSCRIPTION STATUS: $isSubscribed");

      return isSubscribed;
    } catch (e) {
      print("UNSUBSCRIBE API ERROR: $e");
      if (e is DioException) {
        print("STATUS CODE: ${e.response?.statusCode}");
        print("RESPONSE DATA: ${e.response?.data}");
        print("ERROR MESSAGE: ${e.message}");
      }
      rethrow;
    }
  }
}
