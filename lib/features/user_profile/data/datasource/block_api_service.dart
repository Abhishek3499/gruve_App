import 'package:dio/dio.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/datasource/token_storage.dart';
import 'package:gruve_app/features/user_profile/data/dto/block_toggle_response_model.dart';
import 'package:gruve_app/features/blocked/domain/entities/blocked_user_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class BlockApiService {
  static const String _toggleEndpoint = ApiConstants.blockToggle;
  static const String _listEndpoint = ApiConstants.blockList;

  late final Dio _dio;

  void _log(String message) {
    AppLogger.d('?? [BlockApiService] $message');
  }

  BlockApiService() {
    _dio = AppDio.getInstance();
    _log('Initialized shared Dio client');
  }

  Future<List<BlockedUserModel>> fetchBlockedUsers({
    bool forceRefresh = true,
  }) async {
    try {
      _log('🚀 API START - fetchBlockedUsers');
      final token = await TokenStorage.getAccessToken();
      _log('📡 GET $_listEndpoint');

      await CacheManager().invalidatePattern(_listEndpoint);

      final response = await _dio.get(
        _listEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
          extra: {
            'skipCache': true,
            'bypassCache': true,
            'noCache': true,
            'forceRefresh': forceRefresh,
          },
        ),
      );

      _log('✅ API SUCCESS - status=${response.statusCode}');
      _log('🧾 response data=${response.data}');

      // Handle response structure: data.results
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];
        if (data is Map<String, dynamic>) {
          final results = data['results'];
          if (results is List) {
            final users = results
                .map((json) => BlockedUserModel.fromJson(json))
                .toList();
            _log(
              '🎯 parsed ${users.length} blocked users (count: ${data['count']})',
            );
            return users;
          }
        }
      }

      _log('⚠️ Unexpected response format, returning empty list');
      return [];
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      _log('❌ API ERROR - DioException type=${e.type}');
      _log('❌ statusCode=$statusCode');
      _log('❌ responseData=$responseData');
      _log('❌ message=${e.message}');

      rethrow;
    } catch (e) {
      _log('❌ API ERROR - Unexpected error: $e');
      rethrow;
    }
  }

  Future<BlockToggleResponseModel> toggleBlockUser(String userId) async {
    try {
      _log('🚀 API START - toggleBlockUser for userId=$userId');
      final token = await TokenStorage.getAccessToken();
      _log('📡 POST $_toggleEndpoint');
      _log('📦 request body={user_id: $userId}');

      final response = await _dio.post(
        _toggleEndpoint,
        data: {'user_id': userId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {
            'skipCache': true,
            'bypassCache': true,
            'noCache': true,
          },
        ),
      );

      _log('✅ API SUCCESS - status=${response.statusCode}');
      _log('🧾 response data=${response.data}');

      final result = BlockToggleResponseModel.fromJson(response.data);
      _log('🎯 parsed isBlocked=${result.data?.isBlocked}');

      await CacheManager().invalidatePattern(_listEndpoint);

      return result;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      _log('❌ API ERROR - DioException type=${e.type}');
      _log('❌ statusCode=$statusCode');
      _log('❌ responseData=$responseData');
      _log('❌ message=${e.message}');

      rethrow;
    } catch (e) {
      _log('❌ API ERROR - Unexpected error: $e');
      rethrow;
    }
  }
}
