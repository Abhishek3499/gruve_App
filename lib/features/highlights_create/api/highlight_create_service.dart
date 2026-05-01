import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

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
    _dio = AppDio.create(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
    );
  }

  Future<HighlightCreateResponse> createOrUpdateHighlight({
    String? highlightId,
    required String title,
    required List<String> storyIds,
  }) async {
    try {
      final uniqueStoryIds = storyIds.toSet();
      if (uniqueStoryIds.length != storyIds.length) {
        debugPrint('[Highlight] Duplicate story_id detected in request body');
        return HighlightCreateResponse.failure(
          message: 'Story already added to this highlight',
          statusCode: 400,
        );
      }

      debugPrint('[Highlight] POST highlights/');

      final token = await TokenStorage.getAccessToken();
      debugPrint(
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

      debugPrint('[Highlight] Request Body: $requestData');

      final response = await _dio.post(
        'highlights/',
        data: requestData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('[Highlight] Response status=${response.statusCode}');
      debugPrint('[Highlight] Response data=${response.data}');

      return HighlightCreateResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[Highlight] Error: DioException');
      debugPrint('[Highlight] Status Code: ${e.response?.statusCode}');
      debugPrint('[Highlight] Error Data: ${e.response?.data}');
      debugPrint('[Highlight] Message: ${e.message}');

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
      debugPrint('[Highlight] Error: Unknown Exception');
      debugPrint('[Highlight] Message: $e');
      return HighlightCreateResponse.failure(message: 'Something went wrong');
    }
  }
}
