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

  bool _extractSubscriptionState(
    dynamic payload, {
    required bool fallback,
  }) {
    return _findSubscriptionState(payload) ?? fallback;
  }

  bool? _findSubscriptionState(dynamic payload) {
    if (payload is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(payload);
    final directValue =
        _asBool(map['is_subscribed']) ??
        _asBool(map['is_following']) ??
        _asBool(map['subscribed']) ??
        _asBool(map['following']);
    if (directValue != null) {
      return directValue;
    }

    return _findSubscriptionState(map['data']);
  }

  bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }

    return null;
  }

  /// Toggle subscription (subscribe/unsubscribe)
  /// Toggle subscription (subscribe/unsubscribe)
  Future<bool> toggleSubscription(String userId, bool isCurrentlySubscribed) async {
    try {
      print(" TOGGLE SUBSCRIBE API CALL START");
      print("USER ID: $userId, CURRENTLY: $isCurrentlySubscribed");

      final token = await TokenStorage.getAccessToken();

      // If currently subscribed, action is unsubscribe, else subscribe
      final action = isCurrentlySubscribed ? "unsubscribe" : "subscribe";

      final response = await _dio.get(
        "posts/get-post/", // Or the correct endpoint
        queryParameters: {
          "user_id": userId, 
          "action": action,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("SUBSCRIBE API RESPONSE: ${response.data}");
      print("STATUS CODE: ${response.statusCode}");

      final isSubscribed = _extractSubscriptionState(
        response.data,
        fallback: !isCurrentlySubscribed,
      );
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

      final isSubscribed = _extractSubscriptionState(
        response.data,
        fallback: false,
      );
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

      final isSubscribed = _extractSubscriptionState(
        response.data,
        fallback: false,
      );
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
