import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/cursor_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/paginated_response_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_draft_model.dart';
import 'package:gruve_app/features/auth/token_storage.dart';
import 'package:gruve_app/features/camera/utils/image_filter_processor.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class PostService {
  late final Dio _dio;

  bool _isLoading = false;
  String? _lastRequestKey;
  final Map<String, Future<PaginatedPostsResponse>> _inFlightPageRequests = {};

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

  /// Returns true if the path points to a video file.
  static bool _isVideo(String path) {
    final uri = Uri.tryParse(path);
    final cleanPath = uri?.path.toLowerCase() ?? path.toLowerCase();
    return cleanPath.endsWith('.mp4') ||
        cleanPath.endsWith('.mov') ||
        cleanPath.endsWith('.avi') ||
        cleanPath.endsWith('.mkv');
  }

  Future<CreatePostResponse> createPost({
    String? caption,
    String? mediaPath,
    String? locationName,
    bool audienceEveryone = true,
    bool audienceCloseFriends = false,
    bool scheduleReel = false,
    bool uploadHighQuality = false,
    bool hideLikeCount = false,
    bool hideShareCount = false,
    List<String>? taggedUserIds,
  }) async {
    File? tempDownloadedFile;
    try {
      final isVideo = mediaPath != null && mediaPath.isNotEmpty
          ? _isVideo(mediaPath)
          : false;
      AppLogger.d('\n🚀 [PostService] ===== CREATE POST START =====');
      AppLogger.d('📁 [PostService] mediaPath: $mediaPath');

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
          await _dio.download(mediaPath, tempFile.path);
          file = tempFile;
          tempDownloadedFile = tempFile;
          AppLogger.d('📥 [PostService] Downloaded to: ${file.path}');
        } else {
          file = File(mediaPath);
        }

        if (file.existsSync()) {
          final fileName = file.path.replaceAll(r'\', '/').split('/').last;
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
          }
          formData.files.add(
            MapEntry(
              'file',
              await MultipartFile.fromFile(
                uploadFile.path,
                filename: fileName,
                contentType: isVideo
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

      return CreatePostResponse.fromJson(res.data);
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
    }
  }

  Future<Map<String, dynamic>> saveDraft({
    String? caption,
    String? mediaPath,
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
          final isVideo = _isVideo(mediaPath);
          final fileName = mediaPath.replaceAll(r'\', '/').split('/').last;
          File uploadFile = file;
          if (!isVideo) {
            AppLogger.d('🗜️ [PostService] Compressing draft image...');
            try {
              uploadFile = await ImageFilterProcessor.compressImageForUpload(
                file,
                maxFileSizeKB: 400,
              );
            } catch (e) {
              AppLogger.d(
                '⚠️ [PostService] Draft image compression failed, using original: $e',
              );
            }
          }
          dataMap['file'] = await MultipartFile.fromFile(
            uploadFile.path,
            filename: fileName,
            contentType: isVideo
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
          final isVideo = _isVideo(mediaPath);
          final fileName = mediaPath.replaceAll(r'\', '/').split('/').last;
          File uploadFile = file;
          if (!isVideo) {
            AppLogger.d(
              '🗜️ [PostService] Compressing draft image for update...',
            );
            try {
              uploadFile = await ImageFilterProcessor.compressImageForUpload(
                file,
                maxFileSizeKB: 400,
              );
            } catch (e) {
              AppLogger.d(
                '⚠️ [PostService] Draft image compression failed during update, using original: $e',
              );
            }
          }
          dataMap['file'] = await MultipartFile.fromFile(
            uploadFile.path,
            filename: fileName,
            contentType: isVideo
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
  }) async {
    final isInitialLoad = cursor == null || !cursor.isValid;
    final requestKey =
        '${refresh ? 'refresh' : 'page'}_${cursor?.toString() ?? 'first'}_$limit';
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
      AppLogger.d('📡 ${isInitialLoad ? "Initial Load" : "Load More"} API Hit');

      final token = await TokenStorage.getAccessToken();
      final queryParams = <String, dynamic>{
        'limit': limit.clamp(1, 20),
      }; // Increased from 10 to 20

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
        if (e.response?.statusCode == 401) {
          AppLogger.d("Unauthorized error");
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
      return false;
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

  Future<Post> fetchPostById(String postId) async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    try {
      AppLogger.d('🌐 [PostService] GET posts/get-post/?post_id=$postId');
      final res = await _dio.get(
        "posts/get-post/",
        queryParameters: {"post_id": postId},
        options: opts,
      );

      if (res.statusCode == 200 && res.data != null) {
        final dynamic responseData = res.data['data'] ?? res.data;
        if (responseData != null) {
          if (responseData is Map) {
            final list = responseData['posts'] ?? responseData['results'];
            if (list is List && list.isNotEmpty) {
              return Post.fromJson(Map<String, dynamic>.from(list.first));
            }
          }
          return Post.fromJson(Map<String, dynamic>.from(responseData));
        }
      }
      throw Exception('Post not found or invalid format');
    } catch (e) {
      AppLogger.d(
        '⚠️ [PostService] posts/get-post/?post_id=$postId failed: $e. Trying posts/$postId/',
      );
      try {
        final res = await _dio.get("posts/$postId/", options: opts);
        if (res.statusCode == 200 && res.data != null) {
          final dynamic responseData = res.data['data'] ?? res.data;
          return Post.fromJson(Map<String, dynamic>.from(responseData));
        }
      } catch (innerErr) {
        AppLogger.d(
          '❌ [PostService] Both fetch post by ID endpoints failed: $innerErr',
        );
      }
      rethrow;
    }
  }
}
