import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class HighlightCreateResponse {
  final bool success;
  final String message;
  final int? statusCode;
  final HighlightCreateData data;

  HighlightCreateResponse({
    required this.success,
    required this.message,
    required this.data,
    this.statusCode,
  });

  factory HighlightCreateResponse.failure({
    required String message,
    int? statusCode,
  }) {
    return HighlightCreateResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      data: HighlightCreateData.empty(),
    );
  }

  factory HighlightCreateResponse.fromJson(Map<String, dynamic> json) {
    return HighlightCreateResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      statusCode: json['code'] is int
          ? json['code']
          : int.tryParse(json['code']?.toString() ?? ''),
      data: HighlightCreateData.fromJson(json['data'] ?? {}),
    );
  }
}

class HighlightCreateData {
  final String id;
  final String title;
  final int storiesCount;

  HighlightCreateData({
    required this.id,
    required this.title,
    required this.storiesCount,
  });

  factory HighlightCreateData.empty() {
    return HighlightCreateData(id: '', title: '', storiesCount: 0);
  }

  factory HighlightCreateData.fromJson(Map<String, dynamic> json) {
    return HighlightCreateData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      storiesCount: json['stories_count'] is int
          ? json['stories_count']
          : int.tryParse(json['stories_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class HighlightCreateService {
  late final Dio _dio;

  HighlightCreateService() {
    _dio = AppDio.getInstance();
  }

  Future<HighlightCreateResponse> createOrUpdateHighlight({
    String? highlightId,
    required String title,
    required List<String> storyIds,
  }) async {
    try {
      final uniqueStoryIds = storyIds.toSet();
      if (uniqueStoryIds.length != storyIds.length) {
        AppLogger.d('[Highlight] Duplicate story_id detected in request body');
        return HighlightCreateResponse.failure(
          message: 'Story already added to this highlight',
          statusCode: 400,
        );
      }

      AppLogger.d('[Highlight] POST highlights/');

      final token = await TokenStorage.getAccessToken();
      AppLogger.d(
        '[Highlight] Authorization Token: '
        '${token?.isNotEmpty == true ? 'Present' : 'Missing'}',
      );

      final Map<String, dynamic> requestData = {
        'title': title,
        'story_ids': storyIds,
      };

      if (highlightId != null && highlightId.isNotEmpty) {
        requestData['highlight_id'] = highlightId;
      }

      AppLogger.d('[Highlight] Request Body: $requestData');

      final response = await _dio.post(
        ApiConstants.createHighlight,
        data: requestData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      AppLogger.d('[Highlight] Response status=${response.statusCode}');
      AppLogger.d('[Highlight] Response data=${response.data}');

      return HighlightCreateResponse.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.d('[Highlight] Error: DioException');
      AppLogger.d('[Highlight] Status Code: ${e.response?.statusCode}');
      AppLogger.d('[Highlight] Error Data: ${e.response?.data}');
      AppLogger.d('[Highlight] Message: ${e.message}');

      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        final statusCode = e.response?.statusCode;
        return HighlightCreateResponse.fromJson({
          ...responseData,
          'code': responseData['code'] ?? statusCode,
          if ((statusCode == 400 || statusCode == 409) &&
              responseData['message'] == null)
            'message': 'Story already added to this highlight',
        });
      }

      return HighlightCreateResponse.failure(
        message: e.response?.statusCode == 409
            ? 'Story already added to this highlight'
            : 'Something went wrong',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.d('[Highlight] Error: Unknown Exception');
      AppLogger.d('[Highlight] Message: $e');
      return HighlightCreateResponse.failure(message: 'Something went wrong');
    }
  }
}
