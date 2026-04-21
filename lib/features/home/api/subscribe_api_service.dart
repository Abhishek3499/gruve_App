import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class SubscribeApiService {
  static const String _toggleEndpoint = 'profile/subscribe/toggle';

  late final Dio _dio;

  void _log(String message) {
    print('🌐 [SubscribeApiService] $message');
  }

  SubscribeApiService() {
    var base = dotenv.env['BASE_URL']!.trim();
    if (!base.endsWith('/')) {
      base = '$base/';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    _log('Initialized with baseUrl=$base');
  }

  Future<bool> toggleSubscription(String userId) async {
    try {
      _log('🚀 toggleSubscription start for userId=$userId');
      final token = await TokenStorage.getAccessToken();
      final tokenPreview = token == null || token.isEmpty
          ? 'null_or_empty'
          : '${token.substring(0, token.length > 12 ? 12 : token.length)}...';
      _log('🔐 token preview=$tokenPreview');
      _log('📡 POST $_toggleEndpoint');
      _log('📦 request body={user_id: $userId}');

      final response = await _dio.post(
        _toggleEndpoint,
        data: {'user_id': userId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      _log('✅ response status=${response.statusCode}');
      _log('🧾 response data=${response.data}');
      final isFollowing = _extractSubscriptionState(response.data);
      _log('🎯 parsed subscription state=$isFollowing');
      return isFollowing;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      _log('❌ DioException type=${e.type}');
      _log('❌ statusCode=$statusCode');
      _log('❌ responseData=$responseData');
      _log('❌ message=${e.message}');

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
    final result = _findSubscriptionState(payload) ?? false;
    _log('🧠 _extractSubscriptionState result=$result');
    return result;
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
      _log('🔎 direct subscription key matched value=$directValue');
      return directValue;
    }

    _log('🪆 no direct key matched, checking nested data');
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
