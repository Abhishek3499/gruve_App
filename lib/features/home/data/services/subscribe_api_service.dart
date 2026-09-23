import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class SubscribeApiService {
  static const String _toggleEndpoint = ApiConstants.subscribeToggle;

  late final Dio _dio;

  static const String _tag = 'SubscribeApiService';

  SubscribeApiService() {
    _dio = AppDio.getInstance();
    AppLogger.debug(_tag, 'client_initialized');
  }

  Future<bool> toggleSubscription(String userId) async {
    try {
      final token = await TokenStorage.getAccessToken();

      final response = await _dio.post(
        _toggleEndpoint,
        data: {'user_id': userId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'noRetry': true},
        ),
      );

      final isFollowing = _extractSubscriptionState(response.data);
      AppLogger.debug(
        _tag,
        'subscription_parsed',
        data: {'endpoint': _toggleEndpoint, 'isFollowing': isFollowing},
      );
      return isFollowing;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      AppLogger.warning(
        _tag,
        'api_error',
        data: {
          'method': 'POST',
          'endpoint': _toggleEndpoint,
          'type': e.type.name,
          'statusCode': statusCode,
        },
      );

      if (statusCode == 400 &&
          responseData is Map &&
          responseData['message']?.toString().contains(
                'subscribe to yourself',
              ) ==
              true) {
        throw Exception('You cannot subscribe to yourself');
      }

      rethrow;
    }
  }

  bool _extractSubscriptionState(dynamic payload) {
    return _findSubscriptionState(payload) ?? false;
  }

  bool? _findSubscriptionState(dynamic payload) {
    if (payload is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(payload);
    final directValue =
        _asBool(map['is_following']) ??
        _asBool(map['is_subscribed']) ??
        _asBool(map['following']) ??
        _asBool(map['subscribed']);
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
}
