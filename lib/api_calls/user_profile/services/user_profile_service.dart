import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class UserProfileService {
  UserProfileService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: dotenv.env['BASE_URL']!,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 25),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

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
  }) async {
    debugPrint(" User Profile API Called");
    final endpoint = "user/profile/$userId";
    debugPrint(" Endpoint: $endpoint");
    debugPrint(" Fetching user profile for userId: $userId");

    final baseUrl = dotenv.env['BASE_URL']!;
    debugPrint("[UserProfileService] baseUrl: $baseUrl");
    debugPrint("[UserProfileService] Checking network connectivity...");

    final token = await TokenStorage.getAccessToken();
    final tokenPreview = token == null || token.isEmpty
        ? "null_or_empty"
        : "${token.substring(0, token.length > 12 ? 12 : token.length)}...";
    debugPrint("[UserProfileService] token preview: $tokenPreview");

    final queryParams = <String, dynamic>{};
    if (allPage != null) queryParams['all_page'] = allPage;
    if (allLimit != null) queryParams['all_limit'] = allLimit;
    if (trendingPage != null) queryParams['trending_page'] = trendingPage;
    if (trendingLimit != null) queryParams['trending_limit'] = trendingLimit;
    if (likedPage != null) queryParams['liked_page'] = likedPage;
    if (likedLimit != null) queryParams['liked_limit'] = likedLimit;

    debugPrint("[UserProfileService] GET $endpoint");
    debugPrint("[UserProfileService] Query params: $queryParams");
    debugPrint("[UserProfileService] Full URL: $baseUrl/$endpoint");

    const maxAttempts = 2;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint(
          "[UserProfileService] Attempt $attempt/$maxAttempts - Making API call...",
        );

        final response = await _dio.get(
          endpoint,
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        debugPrint(" Status Code: ${response.statusCode}");
        debugPrint(" Response received successfully");
        debugPrint(
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
        final transient = _isTransientDioFailure(e);
        final code = e.response?.statusCode;

        debugPrint("[UserProfileService] DioException caught:");
        debugPrint("  - Type: ${e.type}");
        debugPrint("  - Status Code: $code");
        debugPrint("  - Message: ${e.message}");
        debugPrint("  - Is Transient: $transient");
        debugPrint("  - Attempt: $attempt/$maxAttempts");

        if (transient && attempt < maxAttempts) {
          final waitMs = 200 * attempt;
          debugPrint(
            " [UserProfileService] Transient failure - retry in ${waitMs}ms",
          );
          await Future<void>.delayed(Duration(milliseconds: waitMs));
          continue;
        }

        debugPrint(" [UserProfileService] Giving up after $attempt attempts");
        debugPrint(" [UserProfileService] Final error: $e");
        rethrow;
      } catch (e, st) {
        debugPrint("[UserProfileService] UNEXPECTED ERROR:");
        debugPrint("  - Error: $e");
        debugPrint("  - Stack trace: $st");
        rethrow;
      }
    }

    throw StateError('UserProfileService.getUserProfile: exhausted attempts');
  }
}
