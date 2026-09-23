import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/network/api_exception.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ProfileService {
  ProfileService() : _dio = AppDio.getInstance();

  final Dio _dio;

  static const String _tag = 'ProfileService';

  static bool _isTransientDioFailure(DioException e) {
    final code = e.response?.statusCode;
    if (code != null && {408, 502, 503, 504}.contains(code)) {
      return true;
    }
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  Future<Map<String, dynamic>> getUser({
    int? allPage,
    int? allLimit,
    int? trendingPage,
    int? trendingLimit,
    int? likedPage,
    int? likedLimit,
    CancelToken? cancelToken,
  }) async {
    final token = await TokenStorage.getAccessToken();

    // Build query parameters
    final queryParams = <String, dynamic>{};
    if (allPage != null) queryParams['all_page'] = allPage;
    if (allLimit != null) queryParams['all_limit'] = allLimit;
    if (trendingPage != null) queryParams['trending_page'] = trendingPage;
    if (trendingLimit != null) queryParams['trending_limit'] = trendingLimit;
    if (likedPage != null) queryParams['liked_page'] = likedPage;
    if (likedLimit != null) queryParams['liked_limit'] = likedLimit;

    const maxAttempts = 1;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await _dio.get(
          ApiConstants.profileData,
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
          cancelToken: cancelToken,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }

        AppLogger.warning(
          _tag,
          'unexpected_response_type',
          data: {
            'endpoint': ApiConstants.profileData,
            'actualType': response.data.runtimeType.toString(),
          },
        );
        return <String, dynamic>{};
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          AppLogger.debug(
            _tag,
            'request_cancelled',
            data: {'endpoint': ApiConstants.profileData},
          );
          return <String, dynamic>{};
        }
        final transient = _isTransientDioFailure(e);
        final code = e.response?.statusCode;

        AppLogger.warning(
          _tag,
          'api_error',
          data: {
            'endpoint': ApiConstants.profileData,
            'type': e.type.name,
            'statusCode': code,
            'transient': transient,
            'attempt': attempt,
          },
        );

        if (transient && attempt < maxAttempts) {
          final waitMs = 500 * attempt;
          await Future<void>.delayed(Duration(milliseconds: waitMs));
          continue;
        }

        throw ApiException.fromDio(e, fallback: 'Failed to fetch profile data');
      } catch (e, st) {
        AppLogger.error(
          _tag,
          'unexpected_error',
          data: {'endpoint': ApiConstants.profileData},
          error: e,
          stackTrace: st,
        );
        if (e is ApiException) rethrow;
        throw ApiException('Failed to fetch profile data');
      }
    }
    // Loop always returns from try or rethrows; satisfy return type analysis.
    throw StateError('ProfileService.getUser: exhausted attempts');
  }
}
