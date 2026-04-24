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
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
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
    debugPrint(" Profile Count API Called");
    debugPrint(" Endpoint: user/profile_data/");

    final baseUrl = dotenv.env['BASE_URL']!;
    debugPrint("[ProfileService] baseUrl: $baseUrl");
    debugPrint("[ProfileService] Checking network connectivity...");

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
    debugPrint("[ProfileService] Full URL: $baseUrl user/profile_data/");

    const maxAttempts = 1;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint(
          "[ProfileService] Attempt $attempt/$maxAttempts - Making API call...",
        );

        final response = await _dio.get(
          "user/profile_data/",
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );

        debugPrint(" Status Code: ${response.data}");

        debugPrint(" Status Code: ${response.statusCode}");
        debugPrint(" Response received successfully");

        // Enhanced response logging
        debugPrint("🔍  RAW RESPONSE TYPE: ${response.data.runtimeType}");
        if (response.data != null) {
          if (response.data is Map) {
            final responseMap = Map<String, dynamic>.from(response.data as Map);
            debugPrint(
              "🔍 [ProfileService] RESPONSE KEYS: ${responseMap.keys.toList()}",
            );
            debugPrint("🔍 [ProfileService] FULL RESPONSE: $responseMap");

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
            debugPrint(
              "🔍 [ProfileService] COUNT-RELATED FIELDS: $countFields",
            );

            for (final field in countFields) {
              debugPrint("🔍 [ProfileService] $field: ${responseMap[field]}");
            }

            return responseMap;
          } else {
            debugPrint("🔍 [ProfileService] RESPONSE DATA: ${response.data}");
          }
        } else {
          debugPrint("🔍 [ProfileService] RESPONSE DATA IS NULL");
        }

        if (response.data is Map<String, dynamic>) {
          debugPrint(" Response parsed as Map<String, dynamic>");
          return Map<String, dynamic>.from(response.data);
        }

        if (response.data is Map) {
          debugPrint(" Response parsed as Map");
          return Map<String, dynamic>.from(response.data as Map);
        }

        debugPrint(" Response is not a Map, returning empty");
        return <String, dynamic>{};
      } on DioException catch (e) {
        final transient = _isTransientDioFailure(e);
        final code = e.response?.statusCode;

        debugPrint("[ProfileService] DioException caught:");
        debugPrint("  - Type: ${e.type}");
        debugPrint("  - Status Code: $code");
        debugPrint("  - Message: ${e.message}");
        debugPrint("  - Is Transient: $transient");
        debugPrint("  - Attempt: $attempt/$maxAttempts");

        // Enhanced debugging for connection errors
        if (e.type == DioExceptionType.connectionError) {
          debugPrint("[ProfileService] CONNECTION ERROR DETAILS:");
          debugPrint("  - Base URL: $baseUrl");
          debugPrint(
            "  - Host lookup failed: ${e.message?.contains('Failed host lookup') == true}",
          );
          debugPrint("  - Network available: Checking...");

          // Check if it's a host lookup issue
          if (e.message?.contains('Failed host lookup') == true) {
            debugPrint(
              "[ProfileService] HOST LOOKUP FAILED - Server may be down or URL incorrect",
            );
            debugPrint(
              "[ProfileService] Please check: 1) Server is running 2) URL is correct 3) Internet connection",
            );
          }
        }

        if (transient && attempt < maxAttempts) {
          final waitMs = 500 * attempt;
          debugPrint(
            " [ProfileService] Transient failure - retry in ${waitMs}ms",
          );
          await Future<void>.delayed(Duration(milliseconds: waitMs));
          continue;
        }

        debugPrint(" [ProfileService] Giving up after $attempt attempts");
        debugPrint(" [ProfileService] Final error: $e");
        rethrow;
      } catch (e, st) {
        debugPrint("[ProfileService] UNEXPECTED ERROR:");
        debugPrint("  - Error: $e");
        debugPrint("  - Stack trace: $st");
        rethrow;
      }
    }
    // Loop always returns from try or rethrows; satisfy return type analysis.
    throw StateError('ProfileService.getUser: exhausted attempts');
  }
}
