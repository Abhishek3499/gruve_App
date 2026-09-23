import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
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
        AppLogger.warning(
          'HighlightCreateService',
          'duplicate_story_id',
          data: {'endpoint': ApiConstants.createHighlight},
        );
        return HighlightCreateResponse.failure(
          message: 'Story already added to this highlight',
          statusCode: 400,
        );
      }

      final token = await TokenStorage.getAccessToken();

      final Map<String, dynamic> requestData = {
        'title': title,
        'story_ids': storyIds,
      };

      if (highlightId != null && highlightId.isNotEmpty) {
        requestData['highlight_id'] = highlightId;
      }

      final response = await _dio.post(
        ApiConstants.createHighlight,
        data: requestData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return HighlightCreateResponse.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.warning(
        'HighlightCreateService',
        'api_error',
        data: {
          'method': 'POST',
          'endpoint': ApiConstants.createHighlight,
          'type': e.type.name,
          'statusCode': e.response?.statusCode,
        },
      );

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
      AppLogger.error(
        'HighlightCreateService',
        'unexpected_error',
        data: {'endpoint': ApiConstants.createHighlight},
        error: e,
      );
      return HighlightCreateResponse.failure(message: 'Something went wrong');
    }
  }
}
