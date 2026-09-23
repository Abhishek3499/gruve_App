import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/features/story_preview/data/dto/cursor_model.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/features/story_preview/data/dto/paginated_response_model.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_draft_model.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
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
        return await _dio.get(
          path,
          queryParameters: queryParameters,
          options: options,
        );
      } on DioException catch (e) {
        lastError = e;
        final transient = _isTransientDioFailure(e);
        AppLogger.warning(
          'PostService',
          'api_error',
          data: {
            'method': 'GET',
            'endpoint': path,
            'attempt': attempt,
            'type': e.type.name,
            'statusCode': e.response?.statusCode,
            'transient': transient,
          },
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

    AppLogger.debug(
      'PostService',
      'upload_file_prepared',
      data: {'mediaType': isVideo ? 'video' : 'image', 'fileName': fileName},
    );

    File uploadFile = file;
    if (!isVideo) {
      try {
        uploadFile = await ImageFilterProcessor.compressImageForUpload(
          file,
          maxFileSizeKB: 400,
        );
      } catch (e) {
        AppLogger.warning(
          'PostService',
          'image_compression_failed',
          data: {'error': e.toString()},
        );
      }
    } else {
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
            AppLogger.debug(
              'PostService',
              'video_compressed',
              data: {
                'originalBytes': file.lengthSync(),
                'compressedBytes': compressedFile.lengthSync(),
              },
            );
          }
        }
      } catch (e) {
        AppLogger.warning(
          'PostService',
          'video_compression_failed',
          data: {'error': e.toString()},
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
          final tempDir = Directory.systemTemp;
          final fileName = mediaPath.split('/').last.split('?').first;
          final tempFile = File('${tempDir.path}/$fileName');
          await Dio().download(mediaPath, tempFile.path);
          file = tempFile;
          tempDownloadedFile = tempFile;
          AppLogger.debug(
            'PostService',
            'remote_media_downloaded',
            data: {'path': file.path},
          );
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
          AppLogger.error(
            'PostService',
            'file_not_found',
            data: {'path': file.path},
          );
          throw Exception('File not found at path');
        }
      }

      final res = await _dio.post(
        ApiConstants.createPost,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final response = CreatePostResponse.fromJson(res.data);
      if (response.success) {
        await CacheInvalidationService().onPostCreated(response.data?.id ?? '');
      }
      return response;
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(
        'PostService',
        'unexpected_error',
        data: {'endpoint': ApiConstants.createPost},
        error: e,
      );
      rethrow;
    } finally {
      if (tempDownloadedFile != null && tempDownloadedFile.existsSync()) {
        try {
          await tempDownloadedFile.delete();
        } catch (e) {
          AppLogger.warning(
            'PostService',
            'temp_file_delete_failed',
            data: {'error': e.toString()},
          );
        }
      }
      final compressedTemp = tempCompressedVideo;
      if (compressedTemp != null && compressedTemp.existsSync()) {
        try {
          await compressedTemp.delete();
        } catch (e) {
          AppLogger.warning(
            'PostService',
            'compressed_file_delete_failed',
            data: {'error': e.toString()},
          );
        }
      }
      try {
        if (isVideo) {
          await VideoCompress.deleteAllCache();
        }
      } catch (e) {
        AppLogger.warning(
          'PostService',
          'video_cache_clear_failed',
          data: {'error': e.toString()},
        );
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

      final res = await _dio.post(
        ApiConstants.postDrafts,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      await CacheManager().invalidatePattern(ApiConstants.postDrafts);
      await CacheManager().invalidatePattern('drafts');

      return Map<String, dynamic>.from(res.data);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(
        'PostService',
        'unexpected_error',
        data: {'endpoint': ApiConstants.postDrafts},
        error: e,
      );
      rethrow;
    }
  }

  Future<PaginatedDraftsResponse> getDrafts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final queryParams = {'page': page, 'limit': limit};

      final res = await _getWithRetry(
        ApiConstants.postDrafts,
        queryParameters: queryParams,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          extra: {'skipCache': true, 'bypassCache': true, 'noCache': true},
        ),
      );

      final dynamic raw = res.data;
      if (raw is List) {
        return PaginatedDraftsResponse(
          count: raw.length,
          page: page,
          limit: limit,
          hasNext: false,
          results: raw
              .whereType<Map>()
              .map((e) => PostDraft.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }
      final dynamic data = raw is Map ? (raw['data'] ?? raw) : raw;
      if (data is List) {
        return PaginatedDraftsResponse(
          count: data.length,
          page: page,
          limit: limit,
          hasNext: false,
          results: data
              .whereType<Map>()
              .map((e) => PostDraft.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }
      if (data is Map<String, dynamic>) {
        return PaginatedDraftsResponse.fromJson(data);
      }
      if (data is Map) {
        return PaginatedDraftsResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
      return PaginatedDraftsResponse(
        count: 0,
        page: page,
        limit: limit,
        hasNext: false,
        results: [],
      );
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(
        'PostService',
        'unexpected_error',
        data: {'endpoint': ApiConstants.postDrafts},
        error: e,
      );
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
      final endpoint = ApiConstants.postDraft(draftId);

      final res = await _dio.put(
        endpoint,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      await CacheManager().invalidatePattern(ApiConstants.postDrafts);
      await CacheManager().invalidatePattern('drafts');

      return Map<String, dynamic>.from(res.data);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(
        'PostService',
        'unexpected_error',
        data: {'endpoint': ApiConstants.postDraft(draftId)},
        error: e,
      );
      rethrow;
    }
  }

  Future<void> deleteDraft(String draftId) async {
    final endpoint = ApiConstants.postDraft(draftId);
    try {
      final token = await TokenStorage.getAccessToken();

      await _dio.delete(
        endpoint,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      await CacheManager().invalidatePattern(ApiConstants.postDrafts);
      await CacheManager().invalidatePattern('drafts');
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(
        'PostService',
        'unexpected_error',
        data: {'endpoint': endpoint},
        error: e,
      );
      rethrow;
    }
  }

  Future<PaginatedPostsResponse> getPaginatedPosts({
    CursorModel? cursor,
    int limit = 20, // Increased from 10 to reduce API calls
    bool refresh = false,
    String? feed,
  }) async {
    final requestKey =
        '${refresh ? 'refresh' : 'page'}_${cursor?.toString() ?? 'first'}_${limit}_${feed ?? 'none'}';
    final inFlight = _inFlightPageRequests[requestKey];
    if (inFlight != null) {
      AppLogger.debug(
        'PostService',
        'duplicate_request_joined',
        data: {'requestKey': requestKey},
      );
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
      AppLogger.debug(
        'PostService',
        'duplicate_request_skipped',
        data: {'requestKey': requestKey},
      );
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
      final token = await TokenStorage.getAccessToken();
      final queryParams = <String, dynamic>{
        'limit': limit.clamp(1, 20),
      }; // Increased from 10 to 20

      if (feed != null && feed.isNotEmpty) {
        queryParams['feed'] = feed;
      }

      if (cursor?.isValid == true) {
        queryParams.addAll(cursor!.toJson());
      }

      final res = await _getWithRetry(
        ApiConstants.getPost,
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
        } catch (e, stack) {
          AppLogger.error(
            'PostService',
            'post_parse_failed',
            error: e,
            stackTrace: stack,
          );
        }
      }

      final videoCount = posts.where((p) => p.isVideo).length;
      final imageCount = posts.length - videoCount;

      final nextCursor = responseData['next_cursor'] != null
          ? CursorModel.fromJson(
              responseData['next_cursor'] as Map<String, dynamic>,
            )
          : null;

      final hasMore = responseData['has_more'] as bool? ?? true;

      AppLogger.debug(
        'PostService',
        'api_response',
        data: {
          'endpoint': ApiConstants.getPost,
          'posts': posts.length,
          'videos': videoCount,
          'images': imageCount,
          'hasMore': hasMore,
        },
      );

      final result = PaginatedPostsResponse(
        posts: posts,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );
      completer.complete(result);
      return result;
    } catch (e) {
      AppLogger.error(
        'PostService',
        'get_paginated_posts_failed',
        data: {'endpoint': ApiConstants.getPost},
        error: e,
      );
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
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
      final res = await _getWithRetry(ApiConstants.getPost, options: opts);

      final data = res.data['data'];

      if (data == null) {
        AppLogger.warning(
          'PostService',
          'invalid_response',
          data: {'endpoint': ApiConstants.getPost, 'reason': 'no_data_field'},
        );
        return [];
      }

      List list;
      if (data['posts'] != null) {
        list = data['posts'];
      } else if (data['results'] != null) {
        list = data['results'];
      } else {
        AppLogger.warning(
          'PostService',
          'invalid_response',
          data: {
            'endpoint': ApiConstants.getPost,
            'reason': 'no_posts_or_results_field',
          },
        );
        return [];
      }

      AppLogger.debug(
        'PostService',
        'api_response',
        data: {'endpoint': ApiConstants.getPost, 'posts': list.length},
      );

      return list
          .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      AppLogger.error(
        'PostService',
        'get_posts_failed',
        data: {'endpoint': ApiConstants.getPost},
        error: e,
      );
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
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
      await _dio.post(
        ApiConstants.postLikeToggle,
        data: {"post_id": postId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return true;
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 401) {
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
      final res = await _dio.post(
        ApiConstants.postShare,
        data: {"post_id": postId, "recipient_user_ids": recipientUserIds},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      AppLogger.error(
        'PostService',
        'share_post_failed',
        data: {'endpoint': ApiConstants.postShare},
        error: e,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleSavePost(String postId) async {
    final token = await TokenStorage.getAccessToken();

    final res = await _dio.post(
      ApiConstants.postSaveToggle,
      data: {"post_id": postId},
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    final data = res.data['data'];
    final isSaved = data['is_saved'] as bool;
    final returnedPostId = data['post_id'] as String;

    AppLogger.debug(
      'PostService',
      'post_save_toggled',
      data: {'isSaved': isSaved, 'postId': returnedPostId},
    );

    return {'is_saved': isSaved, 'post_id': returnedPostId};
  }

  Future<List<Post>> fetchSavedPosts() async {
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.get(
        ApiConstants.savedPosts,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final data = res.data['data'];
      final List<dynamic> postsJson = data['posts'] ?? data['results'] ?? [];

      final posts = postsJson
          .map((json) => Post.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      AppLogger.debug(
        'PostService',
        'saved_posts_fetched',
        data: {'posts': posts.length},
      );

      return posts;
    } catch (e) {
      AppLogger.error(
        'PostService',
        'fetch_saved_posts_failed',
        data: {'endpoint': ApiConstants.savedPosts},
        error: e,
      );
      rethrow;
    }
  }

  Future<void> addComment(String postId, String text) async {
    final token = await TokenStorage.getAccessToken();

    try {
      await _dio.post(
        ApiConstants.getPost,
        data: {"post_id": postId, "comment": text},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } catch (_) {
      // Intentionally swallowed: caller does not surface comment-post failures.
    }
  }

  Future<bool> deletePost(String postId) async {
    final endpoint = ApiConstants.post(postId);
    try {
      final token = await TokenStorage.getAccessToken();

      final res = await _dio.delete(
        endpoint,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return res.statusCode == 200 || res.statusCode == 204;
    } on DioException {
      return false;
    } catch (e) {
      AppLogger.error(
        'PostService',
        'unexpected_error',
        data: {'endpoint': endpoint},
        error: e,
      );
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
      AppLogger.debug(
        'PostService',
        'duplicate_fetch_by_id_joined',
        data: {'postId': cleanPostId},
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
      final res = await _dio.get(
        ApiConstants.getPost,
        queryParameters: {"post_id": cleanPostId},
        options: opts,
      );

      if (res.statusCode == 200 && res.data != null) {
        final responseData = res.data['data'] ?? res.data;
        resolved = _tryParsePostResponse(responseData, cleanPostId);
      }
    } catch (e) {
      AppLogger.warning(
        'PostService',
        'api_error',
        data: {
          'method': 'GET',
          'endpoint': ApiConstants.getPost,
          'postId': cleanPostId,
          'error': e.toString(),
        },
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

    AppLogger.debug(
      'PostService',
      'fetch_post_by_id_resolved',
      data: {
        'postId': cleanPostId,
        'resolvedId': post.id,
        'likes': post.likesCount,
        'comments': post.commentsCount,
        'hasAvatar': post.profilePicture.isNotEmpty,
      },
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
        ApiConstants.userProfile(userId),
        queryParameters: const {'all_page': 1, 'all_limit': 20},
        options: opts,
      );
      if (res.statusCode != 200 || res.data == null) return null;
      return _extractPostFromProfilePayload(res.data, postId);
    } on DioException catch (e) {
      AppLogger.warning(
        'PostService',
        'profile_lookup_failed',
        data: {
          'postId': postId,
          'userId': userId,
          'statusCode': e.response?.statusCode,
        },
      );
    } catch (e) {
      AppLogger.warning(
        'PostService',
        'profile_lookup_failed',
        data: {'postId': postId, 'userId': userId, 'error': e.toString()},
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
      AppLogger.warning(
        'PostService',
        'post_response_parse_failed',
        data: {'postId': postId, 'error': e.toString()},
      );
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
