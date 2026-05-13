import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';

import 'package:gruve_app/features/story_preview/api/story_api/model/stroy_response.dart';
import 'package:gruve_app/features/story_preview/api/story_api/model/story_model.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/features/camera/utils/image_filter_processor.dart';

class StoryService {
  late final Dio _dio;

  StoryService() {
    debugPrint('🌍 [StoryService] Initialized');
    _dio = AppDio.create(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
    );
  }

  /// Returns true if the path points to a video file.
  static bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  /// Builds a fresh [FormData] every call — never reuse an instance.
  /// Skips image compression for videos to avoid decode errors.
  Future<FormData> _buildFormData({
    required String caption,
    required File file,
  }) async {
    final isVideo = _isVideo(file.path);
    final fileName = file.path.replaceAll(r'\', '/').split('/').last;

    debugPrint('🎞️ [StoryService] mediaType: ${isVideo ? "VIDEO" : "IMAGE"} | file: $fileName');

    File uploadFile = file;
    if (!isVideo) {
      debugPrint('🗜️ [StoryService] Compressing image...');
      uploadFile = await ImageFilterProcessor.compressImageForUpload(
        file,
        maxFileSizeKB: 400,
      );
    } else {
      debugPrint('⏭️ [StoryService] Skipping compression for video');
    }

    final fileSizeKB = await uploadFile.length() ~/ 1024;
    debugPrint('📏 [StoryService] Upload file size: ${fileSizeKB}KB');

    // Always create a fresh FormData — reusing a finalized instance causes errors
    return FormData.fromMap({
      'caption': caption,
      'file': await MultipartFile.fromFile(
        uploadFile.path,
        filename: fileName,
        contentType: isVideo
            ? DioMediaType('video', 'mp4')
            : DioMediaType('image', 'jpeg'),
      ),
    });
  }

  Future<CreateStoryResponse> createStory({
    required String caption,
    required String mediaPath,
  }) async {
    try {
      debugPrint('\n🚀 [StoryService] ===== CREATE STORY START =====');
      debugPrint('📁 [StoryService] mediaPath: $mediaPath');
      debugPrint('📝 [StoryService] caption: $caption');

      final file = File(mediaPath);
      if (!file.existsSync()) {
        debugPrint('❌ [StoryService] File not found at path!');
        throw Exception('File not found');
      }

      final token = await TokenStorage.getAccessToken();

      // Fresh FormData built here — never reused
      final formData = await _buildFormData(caption: caption, file: file);

      debugPrint('🌐 [StoryService] POST stories/');

      final res = await _dio.post(
        'stories/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      debugPrint('✅ [StoryService] Status: ${res.statusCode}');
      debugPrint('📥 [StoryService] Response: ${res.data}');
      debugPrint('🏁 [StoryService] ===== CREATE STORY END =====\n');

      return CreateStoryResponse.fromJson(res.data);
    } on DioException catch (e) {
      debugPrint('\n❌ [StoryService] DIO ERROR');
      debugPrint('⚠️ [StoryService] type: ${e.type}');
      debugPrint('📊 [StoryService] status: ${e.response?.statusCode}');
      debugPrint('📥 [StoryService] response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('\n💥 [StoryService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  Future<StoriesResponse> fetchStories({
    String? userId,
    int page = 1,
    int limit = 5,
  }) async {
    try {
      debugPrint('\n🚀 [StoryService] ===== FETCH STORIES START =====');
      debugPrint('👤 [StoryService] userId: ${userId ?? 'me'} | page: $page | limit: $limit');

      final token = await TokenStorage.getAccessToken();
      final endpoint = userId == null ? 'stories/me/' : 'stories/user/$userId/';

      debugPrint('🌐 [StoryService] GET $endpoint');

      final res = await _dio.get(
        endpoint,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ [StoryService] Status: ${res.statusCode}');
      final count = res.data['data']?['stories']?.length ?? 0;
      debugPrint('📊 [StoryService] Stories count: $count');
      debugPrint('🏁 [StoryService] ===== FETCH STORIES END =====\n');

      return StoriesResponse.fromJson(res.data);
    } on DioException catch (e) {
      debugPrint('\n❌ [StoryService] DIO ERROR');
      debugPrint('⚠️ [StoryService] type: ${e.type}');
      debugPrint('📊 [StoryService] status: ${e.response?.statusCode}');
      debugPrint('📥 [StoryService] response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('\n💥 [StoryService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }
}
