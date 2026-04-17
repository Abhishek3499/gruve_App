import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class ProfileService {
  ProfileService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: dotenv.env['BASE_URL']!,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 45),
            sendTimeout: const Duration(seconds: 30),
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

  Future<Map<String, dynamic>> getUser({
    int? allPage,
    int? allLimit,
    int? trendingPage,
    int? trendingLimit,
    int? likedPage,
    int? likedLimit,
  }) async {
    debugPrint("🔵 Profile Count API Called");
    debugPrint("📡 Endpoint: /api/v1/user/profile_data/");
    debugPrint("[ProfileService] baseUrl: ${dotenv.env['BASE_URL']}");

    final token = await TokenStorage.getAccessToken();
    final tokenPreview = token == null || token.isEmpty
        ? "null_or_empty"
        : "${token.substring(0, token.length > 12 ? 12 : token.length)}...";
    debugPrint("[ProfileService] token preview: $tokenPreview");

    // Build query parameters
    final queryParams = <String, dynamic>{};
    
    if (allPage != null) queryParams['all_page'] = allPage;
    if (allLimit != null) queryParams['all_limit'] = allLimit;
    if (trendingPage != null) queryParams['trending_page'] = trendingPage;
    if (trendingLimit != null) queryParams['trending_limit'] = trendingLimit;
    if (likedPage != null) queryParams['liked_page'] = likedPage;
    if (likedLimit != null) queryParams['liked_limit'] = likedLimit;

    debugPrint("[ProfileService] GET user/profile_data/");
    debugPrint("[ProfileService] Query params: $queryParams");

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await _dio.get(
          "user/profile_data/",
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        debugPrint("✅ Status Code: ${response.statusCode}");
        debugPrint("📦 Response: ${response.data}");

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
        if (transient && attempt < maxAttempts) {
          final waitMs = 500 * attempt;
          debugPrint(
            "⚠️ [ProfileService] attempt $attempt/$maxAttempts failed "
            "(status=$code type=${e.type}), retry in ${waitMs}ms",
          );
          await Future<void>.delayed(Duration(milliseconds: waitMs));
          continue;
        }
        debugPrint("❌ [ProfileService] giving up after $attempt attempts: $e");
        rethrow;
      } catch (e, st) {
        debugPrint("❌ [ProfileService] unexpected error: $e\n$st");
        rethrow;
      }
    }
    // Loop always returns from try or rethrows; satisfy return type analysis.
    throw StateError('ProfileService.getUser: exhausted attempts');
  }
}
