import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';

import 'package:gruve_app/features/story_preview/data/dto/create_story_response.dart';
import 'package:gruve_app/features/story_preview/domain/entities/story_model.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/features/camera/utils/image_filter_processor.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/local_media_utils.dart';

class StoryService {
  late final Dio _dio;

  StoryService() {
    _dio = AppDio.getInstance();
  }

  /// Builds a fresh [FormData] every call — never reuse an instance.
  /// Skips image compression for videos to avoid decode errors.
  Future<FormData> _buildFormData({
    required String caption,
    required File file,
    required String visibility,
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

    AppLogger.d(
      '[StoryService] mediaType: ${isVideo ? "VIDEO" : "IMAGE"} | file: $fileName',
    );

    File uploadFile = file;
    if (!isVideo) {
      AppLogger.d('[StoryService] Compressing image...');
      uploadFile = await ImageFilterProcessor.compressImageForUpload(
        file,
        maxFileSizeKB: 400,
      );
    } else {
      AppLogger.d('[StoryService] Skipping compression for video');
    }

    final fileSizeKB = await uploadFile.length() ~/ 1024;
    AppLogger.d('[StoryService] Upload file size: ${fileSizeKB}KB');

    // Always create a fresh FormData — reusing a finalized instance causes errors
    return FormData.fromMap({
      'caption': caption,
      'visibility': visibility,
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
    String visibility = 'public',
  }) async {
    try {
      final file = File(mediaPath);
      if (!file.existsSync()) {
        AppLogger.d('[StoryService] File not found at path!');
        throw Exception('File not found');
      }

      final token = await TokenStorage.getAccessToken();

      // Fresh FormData built here — never reused
      final formData = await _buildFormData(
        caption: caption,
        file: file,
        visibility: visibility,
        mimeType: mediaMimeType,
        isMuted: isMuted,
      );

      final res = await _dio.post(
        ApiConstants.stories,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final response = CreateStoryResponse.fromJson(res.data);
      if (response.success) {
        await CacheInvalidationService().onStoryCreated('');
      }
      return response;
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.d('[StoryService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  Future<StoriesResponse> fetchStories({
    String? userId,
    int page = 1,
    int limit = 5,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final endpoint = userId == null
          ? ApiConstants.myStories
          : ApiConstants.userStories(userId);

      final res = await _dio.get(
        endpoint,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return StoriesResponse.fromJson(res.data);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.d('[StoryService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }
}
