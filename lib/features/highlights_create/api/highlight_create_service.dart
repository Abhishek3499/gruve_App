import 'package:dio/dio.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class HighlightCreateResponse {
  final bool success;
  final HighlightCreateData data;

  HighlightCreateResponse({required this.success, required this.data});

  factory HighlightCreateResponse.fromJson(Map<String, dynamic> json) {
    return HighlightCreateResponse(
      success: json['success'] ?? false,
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
      print("🌐 [API] POST highlights/");

      final token = await TokenStorage.getAccessToken();
      print(
        "🔑 [API] Authorization Token: ${token?.isNotEmpty == true ? 'Present' : 'Missing'}",
      );

      final Map<String, dynamic> requestData = {
        'title': title,
        'story_ids': storyIds,
      };

      // Add highlightId only for update operations
      if (highlightId != null && highlightId.isNotEmpty) {
        requestData['highlight_id'] = highlightId;
      }

      print("📦 [API] Request Body: $requestData");

      final response = await _dio.post(
        "highlights/",
        data: requestData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("🔥 [API] Response:");
      print("   Status Code: ${response.statusCode}");
      print("   Data: ${response.data}");

      return HighlightCreateResponse.fromJson(response.data);
    } on DioException catch (e) {
      print("❌ [API] Error: DIO Exception");
      print("   Status Code: ${e.response?.statusCode}");
      print("   Error Data: ${e.response?.data}");
      print("   Message: ${e.message}");
      rethrow;
    } catch (e) {
      print("❌ [API] Error: Unknown Exception");
      print("   Message: $e");
      rethrow;
    }
  }
}
