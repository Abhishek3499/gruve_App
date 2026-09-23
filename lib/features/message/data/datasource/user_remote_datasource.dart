import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/message/data/dto/user_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class UserRemoteDataSource {
  UserRemoteDataSource() : _dio = AppDio.getInstance();

  final Dio _dio;

  Future<dynamic> _get(
    String endpoint, {
    CancelToken? cancelToken,
    bool skipCache = false,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        cancelToken: cancelToken,
        options: skipCache ? Options(extra: const {'skipCache': true}) : null,
      );
      return response.data;
    } on DioException {
      rethrow;
    }
  }

  Future<PaginatedUserResponse> fetchUsers({
    int page = 1,
    CancelToken? cancelToken,
    bool skipCache = false,
  }) async {
    try {
      final rawResponse = await _get(
        '${ApiConstants.users}?page=$page&limit=20',
        cancelToken: cancelToken,
        skipCache: skipCache,
      );

      final response = PaginatedUserResponse.fromJson(rawResponse);
      AppLogger.d(
        '[UserRemoteDataSource] Page ${response.page} loaded: ${response.users.length} users',
      );

      return response;
    } catch (e) {
      AppLogger.d('[UserRemoteDataSource] Exception on page $page: $e');

      rethrow;
    }
  }
}
