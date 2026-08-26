import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/network/api_exception.dart';
import 'package:gruve_app/features/auth/data/datasource/token_storage.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ProfileService {
  ProfileService()
    : _dio = AppDio.getInstance();

  final Dio _dio;

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
    AppLogger.d(" Profile Count API Called");
    AppLogger.d(" Endpoint: user/profile_data/");

    final token = await TokenStorage.getAccessToken();

    // Build query parameters
    final queryParams = <String, dynamic>{};
    if (allPage != null) queryParams['all_page'] = allPage;
    if (allLimit != null) queryParams['all_limit'] = allLimit;
    if (trendingPage != null) queryParams['trending_page'] = trendingPage;
    if (trendingLimit != null) queryParams['trending_limit'] = trendingLimit;
    if (likedPage != null) queryParams['liked_page'] = likedPage;
    if (likedLimit != null) queryParams['liked_limit'] = likedLimit;

    AppLogger.d("[ProfileService] GET user/profile_data/");
    AppLogger.d("[ProfileService] Query params: $queryParams");
    AppLogger.d("[ProfileService] 🔄 [DEDUP TEST] Request will be deduplicated if duplicate");
    const maxAttempts = 1;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        AppLogger.d(
          "[ProfileService] Attempt $attempt/$maxAttempts - Making API call...",
        );

        final response = await _dio.get(
          ApiConstants.profileData,
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
          cancelToken: cancelToken,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        AppLogger.d(" Status Code: ${response.data}");

        AppLogger.d(" Status Code: ${response.statusCode}");
        AppLogger.d(" Response received successfully");

        // Enhanced response logging
        AppLogger.d("🔍  RAW RESPONSE TYPE: ${response.data.runtimeType}");
        if (response.data != null) {
          if (response.data is Map) {
            final responseMap = Map<String, dynamic>.from(response.data as Map);
            AppLogger.d(
              "🔍 [ProfileService] RESPONSE KEYS: ${responseMap.keys.toList()}",
            );
            AppLogger.d("🔍 [ProfileService] FULL RESPONSE: $responseMap");

            // Log specific count-related fields
            final countFields = responseMap.keys
                .where(
                  (key) =>
                      key.toLowerCase().contains('count') ||
                      key.toLowerCase().contains('subscriber') ||
                      key.toLowerCase().contains('follower') ||
                      key.toLowerCase().contains('like') ||
                      key.toLowerCase().contains('video') ||
                      key.toLowerCase().contains('post'),
                )
                .toList();
            AppLogger.d(
              "🔍 [ProfileService] COUNT-RELATED FIELDS: $countFields",
            );

            for (final field in countFields) {
              AppLogger.d("🔍 [ProfileService] $field: ${responseMap[field]}");
            }

            return responseMap;
          } else {
            AppLogger.d("🔍 [ProfileService] RESPONSE DATA: ${response.data}");
          }
        } else {
          AppLogger.d("🔍 [ProfileService] RESPONSE DATA IS NULL");
        }

        if (response.data is Map<String, dynamic>) {
          AppLogger.d(" Response parsed as Map<String, dynamic>");
          return Map<String, dynamic>.from(response.data);
        }

        if (response.data is Map) {
          AppLogger.d(" Response parsed as Map");
          return Map<String, dynamic>.from(response.data as Map);
        }

        AppLogger.d(" Response is not a Map, returning empty");
        return <String, dynamic>{};
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          AppLogger.d("[ProfileService] getUser cancelled");
          return <String, dynamic>{};
        }
        final transient = _isTransientDioFailure(e);
        final code = e.response?.statusCode;

        AppLogger.d("[ProfileService] DioException caught:");
        AppLogger.d("  - Type: ${e.type}");
        AppLogger.d("  - Status Code: $code");
        AppLogger.d("  - Message: ${e.message}");
        AppLogger.d("  - Is Transient: $transient");
        AppLogger.d("  - Attempt: $attempt/$maxAttempts");

        // Enhanced debugging for connection errors
        if (e.type == DioExceptionType.connectionError) {
            AppLogger.d("[ProfileService] CONNECTION ERROR DETAILS:");
            AppLogger.d(
              "  - Host lookup failed: ${e.message?.contains('Failed host lookup') == true}",
            );
          AppLogger.d("  - Network available: Checking...");

          // Check if it's a host lookup issue
          if (e.message?.contains('Failed host lookup') == true) {
            AppLogger.d(
              "[ProfileService] HOST LOOKUP FAILED - Server may be down or URL incorrect",
            );
            AppLogger.d(
              "[ProfileService] Please check: 1) Server is running 2) URL is correct 3) Internet connection",
            );
          }
        }

        if (transient && attempt < maxAttempts) {
          final waitMs = 500 * attempt;
          AppLogger.d(
            " [ProfileService] Transient failure - retry in ${waitMs}ms",
          );
          await Future<void>.delayed(Duration(milliseconds: waitMs));
          continue;
        }

        AppLogger.d(" [ProfileService] Giving up after $attempt attempts");
        AppLogger.d(" [ProfileService] Final error: $e");
        throw ApiException.fromDio(e, fallback: 'Failed to fetch profile data');
      } catch (e, st) {
        AppLogger.d("[ProfileService] UNEXPECTED ERROR:");
        AppLogger.d("  - Error: $e");
        AppLogger.d("  - Stack trace: $st");
        if (e is ApiException) rethrow;
        throw ApiException('Failed to fetch profile data');
      }
    }
    // Loop always returns from try or rethrows; satisfy return type analysis.
    throw StateError('ProfileService.getUser: exhausted attempts');
  }
}
