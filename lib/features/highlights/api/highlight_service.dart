import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class HighlightService {
  late final Dio _dio;

  HighlightService() {
    _dio = AppDio.create(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<HighlightsResponse> fetchMyHighlights() async {
    try {
      _log('[HighlightService] fetchMyHighlights called');

      final token = await TokenStorage.getAccessToken();
      _log(
        '[HighlightService] auth token: '
        '${token?.isNotEmpty == true ? 'present' : 'missing'}',
      );

      final response = await _dio.get(
        "highlights/mine/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      _log('[HighlightService] response status: ${response.statusCode}');

      return HighlightsResponse.fromJson(response.data);
    } on DioException catch (e) {
      _log('[HighlightService] Dio error status: ${e.response?.statusCode}');
      rethrow;
    } catch (e) {
      _log('[HighlightService] unknown error: $e');
      rethrow;
    }
  }

  Future<HighlightResponse> fetchHighlightStories(String highlightId) async {
    try {
      _log('[HighlightService] fetchHighlightStories called');
      _log('[HighlightService] highlightId: $highlightId');

      final token = await TokenStorage.getAccessToken();
      _log(
        '[HighlightService] auth token: '
        '${token?.isNotEmpty == true ? 'present' : 'missing'}',
      );

      final response = await _dio.get(
        "highlights/$highlightId/stories/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      _log('[HighlightService] response status: ${response.statusCode}');

      if (response.data['stories'] != null) {
        _log(
          '[HighlightService] stories count: ${response.data['stories'].length}',
        );
      }

      return HighlightResponse.fromJson(response.data);
    } on DioException catch (e) {
      _log('[HighlightService] Dio error status: ${e.response?.statusCode}');
      _log('[HighlightService] endpoint: /highlights/$highlightId/stories/');
      rethrow;
    } catch (e) {
      _log('[HighlightService] unknown error: $e');
      rethrow;
    }
  }
}
