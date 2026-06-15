import 'package:dio/dio.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class HighlightService {
  late final Dio _dio;

  HighlightService() {
    _dio = AppDio.getInstance();
  }

  void _log(String message) {
    AppLogger.d(message);
    
  }

  Future<HighlightsResponse> fetchMyHighlights({CancelToken? cancelToken}) async {
    try {
      _log('[HighlightService] fetchMyHighlights called');

      final token = await TokenStorage.getAccessToken();
      _log(
        '[HighlightService] auth token: '
        '${token?.isNotEmpty == true ? 'present' : 'missing'}',
      );

      final response = await _dio.get(
        "highlights/mine/",
        cancelToken: cancelToken,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      _log('[HighlightService] response status: ${response.statusCode}');

      return HighlightsResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [HighlightService] fetchMyHighlights cancelled');
        return HighlightsResponse(
          code: 200,
          success: false,
          data: HighlightsData(highlights: []),
        );
      }
      _log('[HighlightService] Dio error status: ${e.response?.statusCode}');
      rethrow;
    } catch (e) {
      _log('[HighlightService] unknown error: $e');
      rethrow;
    }
  }

  Future<HighlightResponse> fetchHighlightStories(String highlightId, {CancelToken? cancelToken}) async {
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
        cancelToken: cancelToken,
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
      if (CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [HighlightService] fetchHighlightStories cancelled');
        return HighlightResponse(
          code: 200,
          success: false,
          message: 'Cancelled',
          data: HighlightModel(
            id: '',
            title: '',
            storiesCount: 0,
            coverMediaUrl: '',
            createdAt: '',
          ),
        );
      }
      _log('[HighlightService] Dio error status: ${e.response?.statusCode}');
      _log('[HighlightService] endpoint: /highlights/$highlightId/stories/');
      rethrow;
    } catch (e) {
      _log('[HighlightService] unknown error: $e');
      rethrow;
    }
  }
}
