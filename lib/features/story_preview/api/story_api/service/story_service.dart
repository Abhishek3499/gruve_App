import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';

import 'package:gruve_app/features/story_preview/api/story_api/model/stroy_response.dart';
import 'package:gruve_app/features/story_preview/api/story_api/model/story_model.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/features/camera/utils/image_filter_processor.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/local_media_utils.dart';

class StoryService {
  late final Dio _dio;

  StoryService() {
    AppLogger.d('🌍 [StoryService] Initialized');
    _dio = AppDio.getInstance();
  }

  /// Builds a fresh [FormData] every call — never reuse an instance.
  /// Skips image compression for videos to avoid decode errors.
  Future<FormData> _buildFormData({
    required String caption,
    required File file,
    String? mimeType,
    bool isMuted = false,
  }) async {
    final isVideo = await LocalMediaUtils.isVideoForUpload(
      file.path,
      mimeType: mimeType,
    );
    final fileName = LocalMediaUtils.uploadFilename(
      file.path,
      isVideo: isVideo,
    );

    AppLogger.d('🎞️ [StoryService] mediaType: ${isVideo ? "VIDEO" : "IMAGE"} | file: $fileName');

    File uploadFile = file;
    if (!isVideo) {
      AppLogger.d('🗜️ [StoryService] Compressing image...');
      uploadFile = await ImageFilterProcessor.compressImageForUpload(
        file,
        maxFileSizeKB: 400,
      );
    } else {
      AppLogger.d('⏭️ [StoryService] Skipping compression for video');
    }

    final fileSizeKB = await uploadFile.length() ~/ 1024;
    AppLogger.d('📏 [StoryService] Upload file size: ${fileSizeKB}KB');

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
    String? mediaMimeType,
    bool isMuted = false,
  }) async {
    try {
      AppLogger.d('\n🚀 [StoryService] ===== CREATE STORY START =====');
      AppLogger.d('📁 [StoryService] mediaPath: $mediaPath');
      AppLogger.d('📝 [StoryService] caption: $caption');

      final file = File(mediaPath);
      if (!file.existsSync()) {
        AppLogger.d('❌ [StoryService] File not found at path!');
        throw Exception('File not found');
      }

      final token = await TokenStorage.getAccessToken();

      // Fresh FormData built here — never reused
      final formData = await _buildFormData(
        caption: caption,
        file: file,
        mimeType: mediaMimeType,
        isMuted: isMuted,
      );

      AppLogger.d('🌐 [StoryService] POST stories/');

      final res = await _dio.post(
        'stories/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      AppLogger.d('✅ [StoryService] Status: ${res.statusCode}');
      AppLogger.d('[StoryService] Response status: ${res.statusCode}');
      AppLogger.d('🏁 [StoryService] ===== CREATE STORY END =====\n');

      final response = CreateStoryResponse.fromJson(res.data);
      if (response.success) {
        await CacheInvalidationService().onStoryCreated('');
      }
      return response;
    } on DioException catch (e) {
      AppLogger.d('\n❌ [StoryService] DIO ERROR');
      AppLogger.d('⚠️ [StoryService] type: ${e.type}');
      AppLogger.d('📊 [StoryService] status: ${e.response?.statusCode}');
      AppLogger.d('📥 [StoryService] response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      AppLogger.d('\n💥 [StoryService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  Future<StoriesResponse> fetchStories({
    String? userId,
    int page = 1,
    int limit = 5,
  }) async {
    try {
      AppLogger.d('\n🚀 [StoryService] ===== FETCH STORIES START =====');
      AppLogger.d('👤 [StoryService] userId: ${userId ?? 'me'} | page: $page | limit: $limit');

      final token = await TokenStorage.getAccessToken();
      final endpoint = userId == null ? 'stories/me/' : 'stories/user/$userId/';

      AppLogger.d('🌐 [StoryService] GET $endpoint');

      final res = await _dio.get(
        endpoint,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      AppLogger.d('✅ [StoryService] Status: ${res.statusCode}');
      final count = res.data['data']?['stories']?.length ?? 0;
      AppLogger.d('📊 [StoryService] Stories count: $count');
      AppLogger.d('🏁 [StoryService] ===== FETCH STORIES END =====\n');

      return StoriesResponse.fromJson(res.data);
    } on DioException catch (e) {
      AppLogger.d('\n❌ [StoryService] DIO ERROR');
      AppLogger.d('⚠️ [StoryService] type: ${e.type}');
      AppLogger.d('📊 [StoryService] status: ${e.response?.statusCode}');
      AppLogger.d('📥 [StoryService] response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      AppLogger.d('\n💥 [StoryService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }
}
