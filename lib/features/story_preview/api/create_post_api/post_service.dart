import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/cursor_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/paginated_response_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_draft_model.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/features/camera/utils/image_filter_processor.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/local_media_utils.dart';
import 'package:video_compress/video_compress.dart';

class PostService {
  late final Dio _dio;

  bool _isLoading = false;
  String? _lastRequestKey;
  final Map<String, Future<PaginatedPostsResponse>> _inFlightPageRequests = {};
  final Map<String, Future<Post>> _inFlightFetchById = {};
  final Map<String, Future<Post?>> _inFlightProfilePostLookup = {};

  PostService() {
    _dio = AppDio.getInstance();
  }

  bool _isTransientDioFailure(DioException e) {
    final code = e.response?.statusCode;
    if (code != null && {408, 429, 502, 503, 504}.contains(code)) {
      return true;
    }

    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  Future<Response<dynamic>> _getWithRetry(
    String path, {
    required Options options,
    Map<String, dynamic>? queryParameters,
    int maxAttempts = 5, // Increased from 3 for better reliability
  }) async {
    DioException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        AppLogger.d(
          '🌐 [PostService] GET $path attempt $attempt/$maxAttempts query=$queryParameters',
        );
        return await _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
        );
      } on DioException catch (e) {
        lastError = e;
        final transient = _isTransientDioFailure(e);
        AppLogger.d(
          '⚠️ [PostService] GET failed attempt=$attempt type=${e.type} status=${e.response?.statusCode} transient=$transient',
        );

        if (!transient || attempt == maxAttempts) {
          rethrow;
        }

        // Exponential backoff: 1s, 2s, 3s, 4s, 5s (was 500ms, 1s, 1.5s)
        await Future<void>.delayed(Duration(milliseconds: 1000 * attempt));
      }
    }

    throw lastError ?? StateError('GET request failed for $path');
  }

  Future<({bool isVideo, File uploadFile, String fileName})>
  _prepareUploadFile({
    required File file,
    required String mediaPath,
    String? mimeType,
    bool isMuted = false,
    void Function(File compressedVideo)? onCompressedVideo,
  }) async {
    final isVideo = await LocalMediaUtils.isVideoForUpload(
      mediaPath,
      mimeType: mimeType,
    );
    final fileName = LocalMediaUtils.uploadFilename(
      mediaPath,
      isVideo: isVideo,
    );

    AppLogger.d(
      '🎞️ [PostService] mediaType: ${isVideo ? "VIDEO" : "IMAGE"} | file: $fileName',
    );

    File uploadFile = file;
    if (!isVideo) {
      AppLogger.d('🗜️ [PostService] Compressing image for post...');
      try {
        uploadFile = await ImageFilterProcessor.compressImageForUpload(
          file,
          maxFileSizeKB: 400,
        );
      } catch (e) {
        AppLogger.d(
          '⚠️ [PostService] Image compression failed, using original: $e',
        );
      }
    } else {
      AppLogger.d('🗜️ [PostService] Compressing video for post...');
      try {
        final mediaInfo = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.DefaultQuality,
          deleteOrigin: false,
          includeAudio: !isMuted,
        );
        if (mediaInfo != null && mediaInfo.path != null) {
          final compressedFile = File(mediaInfo.path!);
          if (compressedFile.existsSync()) {
            uploadFile = compressedFile;
            onCompressedVideo?.call(compressedFile);
            AppLogger.d(
              '🗜️ [PostService] Video compressed successfully: ${file.lengthSync()} -> ${compressedFile.lengthSync()} bytes',
            );
          }
        }
      } catch (e) {
        AppLogger.d(
          '⚠️ [PostService] Video compression failed, using original: $e',
        );
      }
    }

    return (isVideo: isVideo, uploadFile: uploadFile, fileName: fileName);
  }

  Future<CreatePostResponse> createPost({
    String? caption,
    String? mediaPath,
    String? mediaMimeType,
    String? locationName,
    bool audienceEveryone = true,
    bool audienceCloseFriends = false,
    bool scheduleReel = false,
    bool uploadHighQuality = false,
    bool hideLikeCount = false,
    bool hideShareCount = false,
    List<String>? taggedUserIds,
    bool isMuted = false,
  }) async {
    File? tempDownloadedFile;
    File? tempCompressedVideo;
    bool isVideo = false;
    try {
      isVideo = mediaPath != null && mediaPath.isNotEmpty
          ? await LocalMediaUtils.isVideoForUpload(
              mediaPath,
              mimeType: mediaMimeType,
            )
          : false;
      AppLogger.d('\n🚀 [PostService] ===== CREATE POST START =====');
      AppLogger.d('📁 [PostService] mediaPath: $mediaPath (isVideo=$isVideo)');

      final token = await TokenStorage.getAccessToken();

      final formData = FormData();

      if (caption != null && caption.trim().isNotEmpty) {
        formData.fields.add(MapEntry('caption', caption.trim()));
      }
      if (locationName != null && locationName.trim().isNotEmpty) {
        formData.fields.add(MapEntry('location_name', locationName.trim()));
      }

      formData.fields.add(
        MapEntry('audience_everyone', audienceEveryone.toString()),
      );
      formData.fields.add(
        MapEntry('audience_close_friends', audienceCloseFriends.toString()),
      );
      formData.fields.add(MapEntry('schedule_reel', scheduleReel.toString()));
      formData.fields.add(
        MapEntry('upload_high_quality', uploadHighQuality.toString()),
      );
      formData.fields.add(
        MapEntry('hide_like_count', hideLikeCount.toString()),
      );
      formData.fields.add(
        MapEntry('hide_share_count', hideShareCount.toString()),
      );

      if (taggedUserIds != null && taggedUserIds.isNotEmpty) {
        for (final id in taggedUserIds) {
          formData.fields.add(MapEntry('tagged_user_ids', id));
        }
      }

      if (mediaPath != null && mediaPath.isNotEmpty) {
        File file;
        if (mediaPath.startsWith('http://') ||
            mediaPath.startsWith('https://')) {
          AppLogger.d(
            '📥 [PostService] Downloading remote draft media: $mediaPath',
          );
          final tempDir = Directory.systemTemp;
          final fileName = mediaPath.split('/').last.split('?').first;
          final tempFile = File('${tempDir.path}/$fileName');
          await Dio().download(mediaPath, tempFile.path);
          file = tempFile;
          tempDownloadedFile = tempFile;
          AppLogger.d('📥 [PostService] Downloaded to: ${file.path}');
        } else {
          file = File(mediaPath);
        }

        if (file.existsSync()) {
          final prepared = await _prepareUploadFile(
            file: file,
            mediaPath: mediaPath,
            mimeType: mediaMimeType,
            isMuted: isMuted,
            onCompressedVideo: (compressed) => tempCompressedVideo = compressed,
          );
          formData.files.add(
            MapEntry(
              'file',
              await MultipartFile.fromFile(
                prepared.uploadFile.path,
                filename: prepared.fileName,
                contentType: prepared.isVideo
                    ? DioMediaType('video', 'mp4')
                    : DioMediaType('image', 'jpeg'),
              ),
            ),
          );
        } else {
          AppLogger.d('❌ [PostService] File not found at path: ${file.path}');
          throw Exception('File not found at path');
        }
      }

      AppLogger.d('🌐 [PostService] POST posts/create-post/');

      final res = await _dio.post(
        'posts/create-post/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      AppLogger.d('✅ [PostService] Status: ${res.statusCode}');
      AppLogger.d('🏁 [PostService] ===== POST SUCCESS =====\n');

      final response = CreatePostResponse.fromJson(res.data);
      if (response.success) {
        await CacheInvalidationService().onPostCreated(response.data?.id ?? '');
      }
      return response;
    } on DioException catch (e) {
      AppLogger.d('\n❌ [PostService] DIO ERROR');
      AppLogger.d('⚠️ [PostService] type: ${e.type}');
      AppLogger.d('📊 [PostService] status: ${e.response?.statusCode}');
      AppLogger.d(
        '📥 [PostService] response status: ${e.response?.statusCode}',
      );
      rethrow;
    } catch (e) {
      AppLogger.d('\n💥 [PostService] UNKNOWN ERROR: $e');
      rethrow;
    } finally {
      if (tempDownloadedFile != null && tempDownloadedFile.existsSync()) {
        try {
          await tempDownloadedFile.delete();
          AppLogger.d('🧹 [PostService] Temporary downloaded file deleted');
        } catch (e) {
          AppLogger.d('⚠️ [PostService] Failed to delete temp file: $e');
        }
      }
      final compressedTemp = tempCompressedVideo;
      if (compressedTemp != null && compressedTemp.existsSync()) {
        try {
          await compressedTemp.delete();
          AppLogger.d(
            '🧹 [PostService] Temporary compressed video file deleted',
          );
        } catch (e) {
          AppLogger.d('⚠️ [PostService] Failed to delete compressed file: $e');
        }
      }
      try {
        if (isVideo) {
          await VideoCompress.deleteAllCache();
          AppLogger.d('🧹 [PostService] VideoCompress cache cleared');
        }
      } catch (e) {
        AppLogger.d('⚠️ [PostService] Failed to clear VideoCompress cache: $e');
      }
    }
  }

  Future<Map<String, dynamic>> saveDraft({
    String? caption,
    String? mediaPath,
    String? mediaMimeType,
    String? locationName,
    bool audienceEveryone = true,
    bool audienceCloseFriends = false,
    bool scheduleReel = false,
    bool uploadHighQuality = false,
    bool hideLikeCount = false,
    bool hideShareCount = false,
  }) async {
    try {
      AppLogger.d('\n🚀 [PostService] ===== SAVE DRAFT START =====');
      final token = await TokenStorage.getAccessToken();

      final Map<String, dynamic> dataMap = {
        if (caption != null && caption.isNotEmpty) 'caption': caption,
        if (locationName != null && locationName.isNotEmpty)
          'location_name': locationName,
        'audience_everyone': audienceEveryone,
        'audience_close_friends': audienceCloseFriends,
        'schedule_reel': scheduleReel,
        'upload_high_quality': uploadHighQuality,
        'hide_like_count': hideLikeCount,
        'hide_share_count': hideShareCount,
      };

      if (mediaPath != null && mediaPath.isNotEmpty) {
        final file = File(mediaPath);
        if (file.existsSync()) {
          final prepared = await _prepareUploadFile(
            file: file,
            mediaPath: mediaPath,
            mimeType: mediaMimeType,
          );
          dataMap['file'] = await MultipartFile.fromFile(
            prepared.uploadFile.path,
            filename: prepared.fileName,
            contentType: prepared.isVideo
                ? DioMediaType('video', 'mp4')
                : DioMediaType('image', 'jpeg'),
          );
        }
      }

      final formData = FormData.fromMap(dataMap);

      AppLogger.d('🌐 [PostService] POST posts/drafts/');

      final res = await _dio.post(
        'posts/drafts/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      AppLogger.d('✅ [PostService] Save Draft Status: ${res.statusCode}');
      AppLogger.d('🏁 [PostService] ===== SAVE DRAFT SUCCESS =====\n');

      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      AppLogger.d('\n❌ [PostService] SAVE DRAFT DIO ERROR');
      AppLogger.d('⚠️ [PostService] type: ${e.type}');
      AppLogger.d('📊 [PostService] status: ${e.response?.statusCode}');
      AppLogger.d(
        '📥 [PostService] response status: ${e.response?.statusCode}',
      );
      rethrow;
    } catch (e) {
      AppLogger.d('\n💥 [PostService] SAVE DRAFT UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  Future<PaginatedDraftsResponse> getDrafts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.d('🚀 [PostService] ===== GET DRAFTS START =====');
      final token = await TokenStorage.getAccessToken();
      final queryParams = {'page': page, 'limit': limit};

      final res = await _getWithRetry(
        "posts/drafts/",
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      AppLogger.d('✅ [PostService] Get Drafts Status: ${res.statusCode}');
      AppLogger.d('🏁 [PostService] ===== GET DRAFTS SUCCESS =====\n');

      final dynamic data = res.data['data'] ?? res.data;
      return PaginatedDraftsResponse.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      AppLogger.d('❌ [PostService] GET DRAFTS DIO ERROR: $e');
      rethrow;
    } catch (e) {
      AppLogger.d('❌ [PostService] GET DRAFTS UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateDraft({
    required String draftId,
    String? caption,
    String? mediaPath,
    String? mediaMimeType,
    String? locationName,
    bool? audienceEveryone,
    bool? audienceCloseFriends,
    bool? scheduleReel,
    bool? uploadHighQuality,
    bool? hideLikeCount,
    bool? hideShareCount,
    bool clearMedia = false,
  }) async {
    try {
      AppLogger.d('\n🚀 [PostService] ===== UPDATE DRAFT START =====');
      AppLogger.d('🆔 [PostService] draftId: $draftId');
      AppLogger.d('📁 [PostService] mediaPath: $mediaPath');
      final token = await TokenStorage.getAccessToken();

      final Map<String, dynamic> dataMap = {
        'caption': ?caption,
        'location_name': ?locationName,
        'audience_everyone': ?audienceEveryone,
        'audience_close_friends': ?audienceCloseFriends,
        'schedule_reel': ?scheduleReel,
        'upload_high_quality': ?uploadHighQuality,
        'hide_like_count': ?hideLikeCount,
        'hide_share_count': ?hideShareCount,
        'clear_media': clearMedia,
      };

      AppLogger.d('📦 [PostService] updateDraft dataMap: $dataMap');

      if (mediaPath != null &&
          mediaPath.isNotEmpty &&
          !mediaPath.startsWith('http') &&
          !mediaPath.startsWith('https')) {
        final file = File(mediaPath);
        if (file.existsSync()) {
          final prepared = await _prepareUploadFile(
            file: file,
            mediaPath: mediaPath,
            mimeType: mediaMimeType,
          );
          dataMap['file'] = await MultipartFile.fromFile(
            prepared.uploadFile.path,
            filename: prepared.fileName,
            contentType: prepared.isVideo
                ? DioMediaType('video', 'mp4')
                : DioMediaType('image', 'jpeg'),
          );
        }
      }

      final formData = FormData.fromMap(dataMap);

      AppLogger.d('🌐 [PostService] PUT posts/drafts/$draftId/');

      final res = await _dio.put(
        'posts/drafts/$draftId/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      AppLogger.d('✅ [PostService] Update Draft Status: ${res.statusCode}');
      AppLogger.d('📥 [PostService] Update Draft Response body: ${res.data}');
      AppLogger.d('🏁 [PostService] ===== UPDATE DRAFT SUCCESS =====\n');

      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      AppLogger.d('\n❌ [PostService] UPDATE DRAFT DIO ERROR');
      AppLogger.d('⚠️ [PostService] type: ${e.type}');
      AppLogger.d('📊 [PostService] status: ${e.response?.statusCode}');
      AppLogger.d(
        '📥 [PostService] response status: ${e.response?.statusCode}',
      );
      AppLogger.d('📥 [PostService] response body: ${e.response?.data}');
      rethrow;
    } catch (e) {
      AppLogger.d('\n💥 [PostService] UPDATE DRAFT UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  Future<void> deleteDraft(String draftId) async {
    try {
      AppLogger.d('\n🚀 [PostService] ===== DELETE DRAFT START =====');
      final token = await TokenStorage.getAccessToken();

      AppLogger.d('🌐 [PostService] DELETE posts/drafts/$draftId/');

      final res = await _dio.delete(
        'posts/drafts/$draftId/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      AppLogger.d('✅ [PostService] Delete Draft Status: ${res.statusCode}');
      AppLogger.d('🏁 [PostService] ===== DELETE DRAFT SUCCESS =====\n');
    } on DioException catch (e) {
      AppLogger.d('\n❌ [PostService] DELETE DRAFT DIO ERROR');
      AppLogger.d('⚠️ [PostService] type: ${e.type}');
      AppLogger.d('📊 [PostService] status: ${e.response?.statusCode}');
      rethrow;
    } catch (e) {
      AppLogger.d('\n💥 [PostService] DELETE DRAFT UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  Future<PaginatedPostsResponse> getPaginatedPosts({
    CursorModel? cursor,
    int limit = 20, // Increased from 10 to reduce API calls
    bool refresh = false,
    String? feed,
  }) async {
    final isInitialLoad = cursor == null || !cursor.isValid;
    final requestKey =
        '${refresh ? 'refresh' : 'page'}_${cursor?.toString() ?? 'first'}_${limit}_${feed ?? 'none'}';
    final inFlight = _inFlightPageRequests[requestKey];
    if (inFlight != null) {
      AppLogger.d('🔄 PostService: Joining duplicate paginated request');
      return inFlight;
    }

    final completer = Completer<PaginatedPostsResponse>();
    _inFlightPageRequests[requestKey] = completer.future;
    unawaited(
      completer.future.catchError(
        (_) =>
            PaginatedPostsResponse(posts: [], nextCursor: null, hasMore: false),
      ),
    );

    if (_isLoading && !refresh && _lastRequestKey == requestKey) {
      AppLogger.d('🔄 PostService: Skipping duplicate request');
      final result = PaginatedPostsResponse(
        posts: [],
        nextCursor: null,
        hasMore: false,
      );
      completer.complete(result);
      _inFlightPageRequests.remove(requestKey);
      return result;
    }

    _isLoading = true;
    _lastRequestKey = requestKey;

    try {
      AppLogger.d(
        '📡 ${isInitialLoad ? "Initial Load" : "Load More"} API Hit for feed: ${feed ?? "default"}',
      );

      final token = await TokenStorage.getAccessToken();
      final queryParams = <String, dynamic>{
        'limit': limit.clamp(1, 20),
      }; // Increased from 10 to 20

      if (feed != null && feed.isNotEmpty) {
        queryParams['feed'] = feed;
      }

      if (cursor?.isValid == true) {
        queryParams.addAll(cursor!.toJson());
        AppLogger.d(
          '📍 Next Cursor: {created_at: ${cursor.createdAt}, id: ${cursor.id}}',
        );
      }

      final res = await _getWithRetry(
        "posts/get-post/",
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final responseData = res.data['data'] ?? res.data;
      final rawPosts = responseData['posts'] as List<dynamic>? ?? [];

      final posts = <Post>[];

      for (final raw in rawPosts) {
        try {
          final post = Post.fromJson(Map<String, dynamic>.from(raw));

          posts.add(post);

          AppLogger.d(
            '✅ Parsed post: ${post.id} '
            'video=${post.isVideo} '
            'media=${post.media}',
          );
        } catch (e, stack) {
          AppLogger.d('❌ Failed parsing post: $e');
          AppLogger.d('❌ Raw post: $raw');
          AppLogger.d(stack.toString());
        }
      }

      final videoCount = posts.where((p) => p.isVideo).length;
      final imageCount = posts.length - videoCount;
      AppLogger.d(
        '📡 feed API: get-post parsed ${posts.length} posts (🎥 $videoCount videos, 🖼 $imageCount images)',
      );

      final nextCursor = responseData['next_cursor'] != null
          ? CursorModel.fromJson(
              responseData['next_cursor'] as Map<String, dynamic>,
            )
          : null;

      final hasMore = responseData['has_more'] as bool? ?? true;

      AppLogger.d('📊 Has More: $hasMore');
      AppLogger.d('📊 API Posts Count: ${posts.length}');

      final result = PaginatedPostsResponse(
        posts: posts,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );
      completer.complete(result);
      return result;
    } catch (e) {
      AppLogger.d("❌ GET PAGINATED POSTS ERROR: $e");
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          AppLogger.d("Unauthorized error");
          final result = PaginatedPostsResponse(
            posts: [],
            nextCursor: null,
            hasMore: false,
          );
          completer.complete(result);
          return result;
        }
        completer.completeError(e);
        rethrow;
      }
      completer.completeError(e);
      rethrow;
    } finally {
      _isLoading = false;
      _inFlightPageRequests.remove(requestKey);
    }
  }

  Future<List<Post>> getPosts() async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    try {
      final res = await _getWithRetry("posts/get-post/", options: opts);

      final data = res.data['data'];

      if (data == null) {
        AppLogger.d("❌ Invalid response structure - no data field");
        return [];
      }

      List list;
      if (data['posts'] != null) {
        list = data['posts'];
      } else if (data['results'] != null) {
        list = data['results'];
      } else {
        AppLogger.d("❌ Invalid response structure - no posts or results field");
        return [];
      }

      AppLogger.d("📊 TOTAL POSTS FROM API: ${list.length}");

      return list.map((e) {
        final post = Post.fromJson(Map<String, dynamic>.from(e));

        AppLogger.d("✅ PARSED POST:");
        AppLogger.d("ID: ${post.id}");

        return post;
      }).toList();
    } catch (e) {
      AppLogger.d("❌ GET POSTS ERROR: $e");
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          AppLogger.d("Unauthorized error");
          return [];
        }
        rethrow;
      }
      rethrow;
    }
  }

  void resetPagination() {
    _lastRequestKey = null;
    _isLoading = false;
    _inFlightPageRequests.clear();
  }

  Future<bool> likePost(String postId) async {
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.post(
        "posts/like/toggle/",
        data: {"post_id": postId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      AppLogger.d("✅ LIKE SUCCESS: ${res.data}");
      return true;
    } catch (e) {
      AppLogger.d("❌ LIKE ERROR: $e");
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 401) {
          AppLogger.d("Unauthorized error");
          return false;
        }
        if (status != null && status >= 500) {
          return false;
        }
      }
      rethrow;
    }
  }

  Future<bool> sharePost({
    required String postId,
    required List<String> recipientUserIds,
  }) async {
    final token = await TokenStorage.getAccessToken();
    try {
      AppLogger.d(
        '🚀 [PostService] sharePost START postId=$postId, recipients=$recipientUserIds',
      );
      final res = await _dio.post(
        "posts/share/",
        data: {"post_id": postId, "recipient_user_ids": recipientUserIds},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      AppLogger.d("✅ [PostService] SHARE SUCCESS: ${res.data}");
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      AppLogger.d("❌ [PostService] SHARE ERROR: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleSavePost(String postId) async {
    AppLogger.d('🚀 [PostService] toggleSavePost START postId=$postId');
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.post(
        "posts/save/toggle/",
        data: {"post_id": postId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      AppLogger.d("✅ [PostService] SAVE TOGGLE SUCCESS: ${res.data}");

      final data = res.data['data'];
      final isSaved = data['is_saved'] as bool;
      final returnedPostId = data['post_id'] as String;

      AppLogger.d('✅ [PostService] isSaved=$isSaved postId=$returnedPostId');

      return {'is_saved': isSaved, 'post_id': returnedPostId};
    } catch (e) {
      AppLogger.d("❌ [PostService] SAVE TOGGLE ERROR: $e");
      if (e is DioException) {
        AppLogger.d("❌ [PostService] Status: ${e.response?.statusCode}");
        AppLogger.d(
          "❌ [PostService] Response status: ${e.response?.statusCode}",
        );
        if (e.response?.statusCode == 401) {
          AppLogger.d("❌ [PostService] Unauthorized error");
        }
      }
      rethrow;
    }
  }

  Future<List<Post>> fetchSavedPosts() async {
    AppLogger.d('🚀 [PostService] fetchSavedPosts START');
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.get(
        "posts/saved/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      AppLogger.d("✅ [PostService] SAVED POSTS SUCCESS: ${res.data}");

      final data = res.data['data'];
      final List<dynamic> postsJson = data['posts'] ?? data['results'] ?? [];

      final posts = postsJson
          .map((json) => Post.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      AppLogger.d('✅ [PostService] Fetched ${posts.length} saved posts');

      return posts;
    } catch (e) {
      AppLogger.d("❌ [PostService] FETCH SAVED POSTS ERROR: $e");
      if (e is DioException) {
        AppLogger.d("❌ [PostService] Status: ${e.response?.statusCode}");
        AppLogger.d(
          "❌ [PostService] Response status: ${e.response?.statusCode}",
        );
      }
      rethrow;
    }
  }

  Future<void> addComment(String postId, String text) async {
    final token = await TokenStorage.getAccessToken();

    try {
      AppLogger.d("💬 ADD COMMENT → $text");

      final res = await _dio.post(
        "posts/get-post/",
        data: {"post_id": postId, "comment": text},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      AppLogger.d("✅ COMMENT RESPONSE status: ${res.statusCode}");
    } catch (e) {
      if (e is DioException) {
        AppLogger.d("❌ STATUS CODE: ${e.response?.statusCode}");
        AppLogger.d("❌ RESPONSE status: ${e.response?.statusCode}");
      } else {
        AppLogger.d("❌ ERROR: $e");
      }
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      AppLogger.d('\n🚀 [PostService] ===== DELETE POST START =====');
      final token = await TokenStorage.getAccessToken();

      AppLogger.d('🌐 [PostService] DELETE posts/$postId/');

      final res = await _dio.delete(
        'posts/$postId/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      AppLogger.d('✅ [PostService] Delete Post Status: ${res.statusCode}');
      AppLogger.d('🏁 [PostService] ===== DELETE POST SUCCESS =====\n');
      return res.statusCode == 200 || res.statusCode == 204;
    } on DioException catch (e) {
      AppLogger.d('\n❌ [PostService] DELETE POST DIO ERROR');
      AppLogger.d('⚠️ [PostService] type: ${e.type}');
      AppLogger.d('📊 [PostService] status: ${e.response?.statusCode}');
      return false;
    } catch (e) {
      AppLogger.d('\n💥 [PostService] DELETE POST UNKNOWN ERROR: $e');
      return false;
    }
  }

  Future<Post> fetchPostById(
    String postId, {
    String? authorUserId,
    bool allowProfileFallback = true,
  }) async {
    final cleanPostId = postId.startsWith('pst_')
        ? postId.substring(4)
        : postId;
    final authorId = authorUserId?.trim() ?? '';
    final cacheKey = '$cleanPostId|$authorId|p=$allowProfileFallback';
    final inFlight = _inFlightFetchById[cacheKey];
    if (inFlight != null) {
      AppLogger.d(
        '🔄 [PostService] Joining duplicate fetchPostById for $cleanPostId',
      );
      return inFlight;
    }

    final future = _fetchPostByIdImpl(
      cleanPostId,
      authorId,
      allowProfileFallback: allowProfileFallback,
    );
    _inFlightFetchById[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlightFetchById.remove(cacheKey);
    }
  }

  Future<Post> _fetchPostByIdImpl(
    String cleanPostId,
    String authorId, {
    required bool allowProfileFallback,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    Post? resolved;

    // Backend only supports GET posts/get-post/?post_id= (GET posts/{id}/ → 405).
    try {
      AppLogger.d(
        '🌐 [PostService] GET posts/get-post/?post_id=$cleanPostId',
      );
      final res = await _dio.get(
        "posts/get-post/",
        queryParameters: {"post_id": cleanPostId},
        options: opts,
      );

      if (res.statusCode == 200 && res.data != null) {
        final responseData = res.data['data'] ?? res.data;
        resolved = _tryParsePostResponse(responseData, cleanPostId);
      }
    } catch (e) {
      AppLogger.d(
        '⚠️ [PostService] posts/get-post/?post_id=$cleanPostId failed: $e',
      );
    }

    if (_isCompleteFetchedPost(resolved, cleanPostId)) {
      return _finalizeFetchedPostAsync(
        resolved!,
        cleanPostId,
        authorId,
        allowProfileFallback: allowProfileFallback,
        profileAlreadyChecked: false,
      );
    }

    var profileAlreadyChecked = false;
    if (!_isCompleteFetchedPost(resolved, cleanPostId) &&
        allowProfileFallback &&
        authorId.isNotEmpty) {
      profileAlreadyChecked = true;
      final profilePost = await _findPostInUserProfile(
        cleanPostId,
        authorId,
        opts,
      );
      if (profilePost != null) {
        resolved = resolved == null
            ? profilePost
            : profilePost.mergedWith(other: resolved);
      }
    }

    if (resolved == null) {
      throw Exception('Post not found or invalid format: $cleanPostId');
    }

    return _finalizeFetchedPostAsync(
      resolved,
      cleanPostId,
      authorId,
      allowProfileFallback: allowProfileFallback,
      profileAlreadyChecked: profileAlreadyChecked,
    );
  }

  Future<Post> _finalizeFetchedPostAsync(
    Post resolved,
    String cleanPostId,
    String authorId, {
    required bool allowProfileFallback,
    required bool profileAlreadyChecked,
  }) async {
    var post = resolved;

    if (post.id.isEmpty) {
      post = post.mergedWith(
        other: Post(
          id: cleanPostId,
          caption: '',
          media: '',
          userId: authorId.isNotEmpty ? authorId : 'unknown',
          likesCount: 0,
          commentsCount: 0,
          isLiked: false,
          username: 'unknown',
          isSubscribed: false,
          profilePicture: '',
        ),
      );
    }

    if (_needsProfileMetadataEnrichment(post) &&
        allowProfileFallback &&
        !profileAlreadyChecked &&
        authorId.isNotEmpty) {
      final token = await TokenStorage.getAccessToken();
      final profilePost = await _findPostInUserProfile(
        cleanPostId,
        authorId,
        Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (profilePost != null) {
        post = profilePost.mergedWith(other: post);
      }
    }

    if (!_isCompleteFetchedPost(post, cleanPostId)) {
      throw Exception('Post media not available: $cleanPostId');
    }

    AppLogger.d(
      '✅ [PostService] fetchPostById $cleanPostId → id=${post.id}, media=${post.media.length > 80 ? '${post.media.substring(0, 80)}…' : post.media}, likes=${post.likesCount}, comments=${post.commentsCount}, avatar=${post.profilePicture.isNotEmpty}',
    );
    return post;
  }

  bool _needsProfileMetadataEnrichment(Post post) {
    return post.profilePicture.trim().isEmpty ||
        post.username.trim().isEmpty ||
        post.username == 'unknown';
  }

  Future<Post?> _findPostInUserProfile(
    String postId,
    String userId,
    Options opts,
  ) async {
    final lookupKey = '$userId|$postId';
    final inFlight = _inFlightProfilePostLookup[lookupKey];
    if (inFlight != null) return inFlight;

    final future = _findPostInUserProfileOnce(postId, userId, opts);
    _inFlightProfilePostLookup[lookupKey] = future;
    try {
      return await future;
    } finally {
      _inFlightProfilePostLookup.remove(lookupKey);
    }
  }

  Future<Post?> _findPostInUserProfileOnce(
    String postId,
    String userId,
    Options opts,
  ) async {
    try {
      final res = await _dio.get(
        'user/profile/$userId/',
        queryParameters: const {'all_page': 1, 'all_limit': 20},
        options: opts,
      );
      if (res.statusCode != 200 || res.data == null) return null;
      return _extractPostFromProfilePayload(res.data, postId);
    } on DioException catch (e) {
      AppLogger.d(
        '⚠️ [PostService] profile lookup for post $postId user $userId: ${e.response?.statusCode}',
      );
    } catch (e) {
      AppLogger.d(
        '⚠️ [PostService] profile lookup for post $postId user $userId failed: $e',
      );
    }
    return null;
  }

  Post? _extractPostFromProfilePayload(dynamic payload, String postId) {
    final root = payload is Map ? (payload['data'] ?? payload) : null;
    if (root is! Map) return null;

    final rootMap = Map<String, dynamic>.from(root);
    final postsRoot = rootMap['posts'];
    if (postsRoot is! Map) return null;

    final postsMap = Map<String, dynamic>.from(postsRoot);
    for (final tabKey in ['all', 'trending', 'liked', 'likes']) {
      final tab = postsMap[tabKey];
      if (tab is! Map) continue;
      final tabMap = Map<String, dynamic>.from(tab);
      final results = tabMap['results'];
      if (results is! List) continue;

      for (final item in results) {
        if (item is! Map) continue;
        final itemMap = Map<String, dynamic>.from(item);
        final itemId = _readPostId(
          itemMap['id'] ?? itemMap['post_id'] ?? itemMap['postId'],
        );
        if (itemId != null && _idsMatch(itemId, postId)) {
          if (rootMap['user'] is Map) {
            final userMap = Map<String, dynamic>.from(rootMap['user'] as Map);
            if (itemMap['profile_picture'] == null &&
                itemMap['profilePicture'] == null) {
              final avatar = userMap['profile_picture'] ?? userMap['avatar'];
              if (avatar != null && avatar.toString().trim().isNotEmpty) {
                itemMap['profile_picture'] = avatar;
              }
            }
            if (itemMap['username'] == null ||
                itemMap['username'].toString().trim().isEmpty) {
              final username = userMap['username']?.toString();
              if (username != null && username.isNotEmpty) {
                itemMap['username'] = username;
              }
            }
            if (itemMap['user'] == null && userMap.isNotEmpty) {
              itemMap['user'] = userMap;
            }
          }

          return Post.fromJson(itemMap);
        }
      }
    }
    return null;
  }

  Post? _tryParsePostResponse(dynamic responseData, String postId) {
    try {
      return _postFromResponseData(responseData, postId);
    } catch (e) {
      AppLogger.d('⚠️ [PostService] Could not parse post $postId: $e');
      return null;
    }
  }

  bool _isCompleteFetchedPost(Post? post, String expectedId) {
    if (post == null) return false;
    if (post.id.isNotEmpty && !_idsMatch(post.id, expectedId)) return false;
    if (post.isVideo) {
      final media = post.media.trim();
      return media.isNotEmpty &&
          (media.startsWith('http://') || media.startsWith('https://'));
    }
    return post.hasPlayableMedia;
  }

  /// Resolves the requested [postId] from API payloads that may be a single post
  /// or a paginated list (never parse feed wrappers as posts).
  Post _postFromResponseData(dynamic responseData, String postId) {
    if (responseData is! Map) {
      throw Exception('Post not found or invalid format');
    }

    final map = Map<String, dynamic>.from(responseData);

    if (_mapLooksLikePost(map)) {
      final directId = _readPostId(
        map['id'] ?? map['post_id'] ?? map['postId'],
      );
      if (directId == null || _idsMatch(directId, postId)) {
        return Post.fromJson(map);
      }
    }

    final singlePost = map['post'];
    if (singlePost is Map) {
      return Post.fromJson(Map<String, dynamic>.from(singlePost));
    }

    for (final listKey in ['posts', 'results', 'items']) {
      final list = map[listKey];
      if (list is! List || list.isEmpty) continue;

      for (final item in list) {
        if (item is! Map) continue;
        final itemMap = Map<String, dynamic>.from(item);
        final itemId = _readPostId(
          itemMap['id'] ?? itemMap['post_id'] ?? itemMap['postId'],
        );
        if (itemId != null && _idsMatch(itemId, postId)) {
          return Post.fromJson(itemMap);
        }
      }

      if (list.length == 1 && list.first is Map) {
        return Post.fromJson(Map<String, dynamic>.from(list.first as Map));
      }
    }

    throw Exception('Post $postId not found in response');
  }

  bool _mapLooksLikePost(Map<String, dynamic> map) {
    return map.containsKey('id') ||
        map.containsKey('post_id') ||
        map.containsKey('postId') ||
        map.containsKey('media_url') ||
        map.containsKey('mediaUrl') ||
        map.containsKey('media') ||
        map.containsKey('file') ||
        map.containsKey('video_url');
  }

  bool _idsMatch(String a, String b) {
    final na = a.startsWith('pst_') ? a.substring(4) : a;
    final nb = b.startsWith('pst_') ? b.substring(4) : b;
    return na == nb;
  }

  String? _readPostId(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('pst_')) return value.substring(4);
    return value;
  }
}
