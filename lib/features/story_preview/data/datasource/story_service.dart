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
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          // Story view/active state changes constantly and must always
          // reflect the backend at tap time. 'stories/user/{id}/' contains
          // '/user/', so CacheConfigs.getConfigForEndpoint matches it to the
          // 'profile' bucket (5min memory / 30min disk TTL) before it ever
          // reaches the '/stories' check — skipCache is what actually keeps
          // this endpoint live, not the (now removed) dedicated stories bucket.
          extra: const {'skipCache': true},
        ),
      );

      return StoriesResponse.fromJson(res.data);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.d('[StoryService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  /// Records a view for [storyId]. Idempotent — safe to call again for the
  /// same story (the backend returns `already_viewed: true` on retries).
  Future<StoryViewResponse> recordView(String storyId) async {
    try {
      final token = await TokenStorage.getAccessToken();

      final res = await _dio.post(
        ApiConstants.storyView(storyId),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return StoryViewResponse.fromJson(res.data);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.d('[StoryService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  /// Fetches the list of users who viewed [storyId] (own stories only).
  Future<StoryViewsResponse> fetchStoryViews(
    String storyId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();

      final res = await _dio.get(
        ApiConstants.storyViews(storyId),
        queryParameters: {'page': page, 'limit': limit},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: const {'skipCache': true},
        ),
      );

      return StoryViewsResponse.fromJson(res.data);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.d('[StoryService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }
}
