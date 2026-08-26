import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/features/profile/data/models/user_profile_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class UserProfileService {
  UserProfileService()
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

  Future<Map<String, dynamic>> getUserProfile({
    required String userId,
    int? allPage,
    int? allLimit,
    int? trendingPage,
    int? trendingLimit,
    int? likedPage,
    int? likedLimit,
    CancelToken? cancelToken,
  }) async {
    AppLogger.d(" User Profile API Called");
    final endpoint = ApiConstants.userProfile(userId);
    AppLogger.d(" Endpoint: $endpoint");
    AppLogger.d(" Fetching user profile for userId: $userId");

    final token = await TokenStorage.getAccessToken();

    final queryParams = <String, dynamic>{};
    if (allPage != null) queryParams['all_page'] = allPage;
    if (allLimit != null) queryParams['all_limit'] = allLimit;
    if (trendingPage != null) queryParams['trending_page'] = trendingPage;
    if (trendingLimit != null) queryParams['trending_limit'] = trendingLimit;
    if (likedPage != null) queryParams['liked_page'] = likedPage;
    if (likedLimit != null) queryParams['liked_limit'] = likedLimit;

    AppLogger.d("[UserProfileService] GET $endpoint");
    AppLogger.d("[UserProfileService] Query params: $queryParams");
    const maxAttempts = 1;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        AppLogger.d(
          "[UserProfileService] Attempt $attempt/$maxAttempts - Making API call...",
        );

        final response = await _dio.get(
          endpoint,
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
          cancelToken: cancelToken,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        AppLogger.d(" Status Code: ${response.statusCode}");
        AppLogger.d(" Response received successfully");
        AppLogger.d(
          "[UserProfileService] RAW RESPONSE TYPE: ${response.data.runtimeType}",
        );

        if (response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }

        if (response.data is Map) {
          return Map<String, dynamic>.from(response.data as Map);
        }

        return <String, dynamic>{};
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          AppLogger.d("[UserProfileService] getUserProfile cancelled");
          return <String, dynamic>{};
        }
        final transient = _isTransientDioFailure(e);
        final code = e.response?.statusCode;

        AppLogger.d("[UserProfileService] DioException caught:");
        AppLogger.d("  - Type: ${e.type}");
        AppLogger.d("  - Status Code: $code");
        AppLogger.d("  - Message: ${e.message}");
        AppLogger.d("  - Is Transient: $transient");
        AppLogger.d("  - Attempt: $attempt/$maxAttempts");

        if (transient && attempt < maxAttempts) {
          final waitMs = 500 * attempt;
          AppLogger.d(
            " [UserProfileService] Transient failure - retry in ${waitMs}ms",
          );
          await Future<void>.delayed(Duration(milliseconds: waitMs));
          continue;
        }

        AppLogger.d(" [UserProfileService] Giving up after $attempt attempts");
        AppLogger.d(" [UserProfileService] Final error: $e");
        rethrow;
      } catch (e, st) {
        AppLogger.d("[UserProfileService] UNEXPECTED ERROR:");
        AppLogger.d("  - Error: $e");
        AppLogger.d("  - Stack trace: $st");
        rethrow;
      }
    }

    throw StateError('UserProfileService.getUserProfile: exhausted attempts');
  }
  Future<UserProfile> getUserProfileModel(String userId, {CancelToken? cancelToken}) async {
    final data = await getUserProfile(userId: userId, cancelToken: cancelToken);
    return UserProfile.fromJson(data['data'] ?? data);
  }
}
