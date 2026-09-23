import 'package:dio/dio.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/features/user_profile/data/dto/block_toggle_response_model.dart';
import 'package:gruve_app/features/blocked/domain/entities/blocked_user_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class BlockApiService {
  static const String _toggleEndpoint = ApiConstants.blockToggle;
  static const String _listEndpoint = ApiConstants.blockList;

  late final Dio _dio;

  BlockApiService() {
    _dio = AppDio.getInstance();
    AppLogger.debug('BlockApiService', 'client_initialized');
  }

  Future<List<BlockedUserModel>> fetchBlockedUsers({
    bool forceRefresh = true,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();

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
            AppLogger.debug(
              'BlockApiService',
              'blocked_users_parsed',
              data: {'endpoint': _listEndpoint, 'count': users.length},
            );
            return users;
          }
        }
      }

      AppLogger.warning(
        'BlockApiService',
        'unexpected_response_format',
        data: {'endpoint': _listEndpoint},
      );
      return [];
    } on DioException catch (e) {
      AppLogger.warning(
        'BlockApiService',
        'api_error',
        data: {
          'method': 'GET',
          'endpoint': _listEndpoint,
          'type': e.type.name,
          'statusCode': e.response?.statusCode,
        },
      );
      rethrow;
    } catch (e) {
      AppLogger.error(
        'BlockApiService',
        'unexpected_error',
        data: {'endpoint': _listEndpoint},
        error: e,
      );
      rethrow;
    }
  }

  Future<BlockToggleResponseModel> toggleBlockUser(String userId) async {
    try {
      final token = await TokenStorage.getAccessToken();

      final response = await _dio.post(
        _toggleEndpoint,
        data: {'user_id': userId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'skipCache': true, 'bypassCache': true, 'noCache': true},
        ),
      );

      final result = BlockToggleResponseModel.fromJson(response.data);
      AppLogger.debug(
        'BlockApiService',
        'toggle_parsed',
        data: {
          'endpoint': _toggleEndpoint,
          'isBlocked': result.data?.isBlocked,
        },
      );

      await CacheManager().invalidatePattern(_listEndpoint);

      return result;
    } on DioException catch (e) {
      AppLogger.warning(
        'BlockApiService',
        'api_error',
        data: {
          'method': 'POST',
          'endpoint': _toggleEndpoint,
          'type': e.type.name,
          'statusCode': e.response?.statusCode,
        },
      );
      rethrow;
    } catch (e) {
      AppLogger.error(
        'BlockApiService',
        'unexpected_error',
        data: {'endpoint': _toggleEndpoint},
        error: e,
      );
      rethrow;
    }
  }
}
