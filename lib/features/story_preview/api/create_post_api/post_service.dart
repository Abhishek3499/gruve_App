import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/cursor_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/paginated_response_model.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class PostService {
  late final Dio _dio;

  bool _isLoading = false;
  String? _lastRequestKey;

  PostService() {
    _dio = AppDio.create(receiveTimeout: const Duration(seconds: 45));
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
    int maxAttempts = 3,
  }) async {
    DioException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint(
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
        debugPrint(
          '⚠️ [PostService] GET failed attempt=$attempt type=${e.type} status=${e.response?.statusCode} transient=$transient',
        );

        if (!transient || attempt == maxAttempts) {
          rethrow;
        }

        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    throw lastError ?? StateError('GET request failed for $path');
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
  /// Videos skip image compression to avoid decode errors.
  Future<FormData> _buildFormData({
    required String caption,
    required File file,
  }) async {
    final isVideo = _isVideo(file.path);
    final fileName = file.path.replaceAll(r'\', '/').split('/').last;

    debugPrint(
      '🎞️ [PostService] mediaType: ${isVideo ? "VIDEO" : "IMAGE"} | file: $fileName',
    );

    final fileSizeKB = await file.length() ~/ 1024;
    debugPrint('📏 [PostService] Upload file size: ${fileSizeKB}KB');

    // Always create a fresh FormData — reusing a finalized instance causes errors
    return FormData.fromMap({
      'caption': caption,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: isVideo
            ? DioMediaType('video', 'mp4')
            : DioMediaType('image', 'jpeg'),
      ),
    });
  }

  Future<CreatePostResponse> createPost({
    required String caption,
    required String mediaPath,
  }) async {
    try {
      final isVideo = _isVideo(mediaPath);
      debugPrint('\n🚀 [PostService] ===== CREATE POST START =====');
      debugPrint('🎥 [PostService] Type: ${isVideo ? "VIDEO" : "IMAGE"}');
      debugPrint('📁 [PostService] mediaPath: $mediaPath');
      debugPrint('📝 [PostService] caption: $caption');

      final token = await TokenStorage.getAccessToken();
      final file = File(mediaPath);

      if (!file.existsSync()) {
        debugPrint('❌ [PostService] File not found at path!');
        throw Exception('File not found');
      }

      final formData = await _buildFormData(caption: caption, file: file);

      debugPrint('🌐 [PostService] POST posts/create-post/');

      final res = await _dio.post(
        'posts/create-post/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      debugPrint('✅ [PostService] Status: ${res.statusCode}');
      debugPrint('📥 [PostService] Response: ${res.data}');
      debugPrint(
        '🏁 [PostService] ===== ${isVideo ? "VIDEO" : "IMAGE"} POST SUCCESS =====\n',
      );

      return CreatePostResponse.fromJson(res.data);
    } on DioException catch (e) {
      debugPrint('\n❌ [PostService] DIO ERROR');
      debugPrint('⚠️ [PostService] type: ${e.type}');
      debugPrint('📊 [PostService] status: ${e.response?.statusCode}');
      debugPrint('📥 [PostService] response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('\n💥 [PostService] UNKNOWN ERROR: $e');
      rethrow;
    }
  }

  Future<PaginatedPostsResponse> getPaginatedPosts({
    CursorModel? cursor,
    int limit = 10,
    bool refresh = false,
  }) async {
    final isInitialLoad = cursor == null || !cursor.isValid;
    final requestKey = '${cursor?.toString() ?? 'first'}_$limit';
    if (_isLoading && !refresh && _lastRequestKey == requestKey) {
      debugPrint('🔄 PostService: Skipping duplicate request');
      return PaginatedPostsResponse(
        posts: [],
        nextCursor: null,
        hasMore: false,
      );
    }

    _isLoading = true;
    _lastRequestKey = requestKey;

    try {
      debugPrint('📡 ${isInitialLoad ? "Initial Load" : "Load More"} API Hit');

      final token = await TokenStorage.getAccessToken();
      final queryParams = <String, dynamic>{'limit': limit.clamp(1, 10)};

      if (cursor?.isValid == true) {
        queryParams.addAll(cursor!.toJson());
        debugPrint(
          '📍 Next Cursor: {created_at: ${cursor.createdAt}, id: ${cursor.id}}',
        );
      }

      final res = await _getWithRetry(
        "posts/get-post/",
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint('📡 [PostService] Raw API response: ${res.data}');

      final responseData = res.data['data'] ?? res.data;
      final rawPosts = responseData['posts'] as List<dynamic>? ?? [];

      final posts = <Post>[];

      for (final raw in rawPosts) {
        try {
          final post = Post.fromJson(Map<String, dynamic>.from(raw));

          posts.add(post);

          debugPrint(
            '✅ Parsed post: ${post.id} '
            'video=${post.isVideo} '
            'media=${post.media}',
          );
        } catch (e, stack) {
          debugPrint('❌ Failed parsing post: $e');
          debugPrint('❌ Raw post: $raw');
          debugPrint(stack.toString());
        }
      }

      final videoCount = posts.where((p) => p.isVideo).length;
      final imageCount = posts.length - videoCount;
      debugPrint(
        '📡 feed API: get-post parsed ${posts.length} posts (🎥 $videoCount videos, 🖼 $imageCount images)',
      );

      final nextCursor = responseData['next_cursor'] != null
          ? CursorModel.fromJson(
              responseData['next_cursor'] as Map<String, dynamic>,
            )
          : null;

      final hasMore = responseData['has_more'] as bool? ?? true;

      debugPrint('📊 Has More: $hasMore');
      debugPrint('📊 API Posts Count: ${posts.length}');

      return PaginatedPostsResponse(
        posts: posts,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );
    } catch (e) {
      debugPrint("❌ GET PAGINATED POSTS ERROR: $e");
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          debugPrint("Unauthorized error");
          return PaginatedPostsResponse(
            posts: [],
            nextCursor: null,
            hasMore: false,
          );
        }
        rethrow;
      }
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<List<Post>> getPosts() async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    try {
      final res = await _getWithRetry("posts/get-post/", options: opts);

      debugPrint("📡 FULL API RESPONSE: ${res.data}");

      final data = res.data['data'];

      if (data == null) {
        debugPrint("❌ Invalid response structure - no data field");
        return [];
      }

      List list;
      if (data['posts'] != null) {
        list = data['posts'];
      } else if (data['results'] != null) {
        list = data['results'];
      } else {
        debugPrint("❌ Invalid response structure - no posts or results field");
        return [];
      }

      debugPrint("📊 TOTAL POSTS FROM API: ${list.length}");

      return list.map((e) {
        final post = Post.fromJson(Map<String, dynamic>.from(e));

        debugPrint("✅ PARSED POST:");
        debugPrint("ID: ${post.id}");
        debugPrint("CAPTION: ${post.caption}");
        debugPrint("MEDIA: ${post.media}");
        debugPrint("❤️ Likes: ${post.likesCount}");
        debugPrint("💬 Comments: ${post.commentsCount}");
        debugPrint("👤 User: ${post.username}");
        debugPrint("🔔 Subscribed: ${post.isSubscribed}");

        return post;
      }).toList();
    } catch (e) {
      debugPrint("❌ GET POSTS ERROR: $e");
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          debugPrint("Unauthorized error");
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
  }

  Future<bool> likePost(String postId) async {
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.post(
        "posts/like/toggle/",
        data: {"post_id": postId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ LIKE SUCCESS: ${res.data}");
      return true;
    } catch (e) {
      debugPrint("❌ LIKE ERROR: $e");
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          debugPrint("Unauthorized error");
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
    debugPrint('🚀 [PostService] toggleSavePost START postId=$postId');
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.post(
        "posts/save/toggle/",
        data: {"post_id": postId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [PostService] SAVE TOGGLE SUCCESS: ${res.data}");

      final data = res.data['data'];
      final isSaved = data['is_saved'] as bool;
      final returnedPostId = data['post_id'] as String;

      debugPrint('✅ [PostService] isSaved=$isSaved postId=$returnedPostId');

      return {'is_saved': isSaved, 'post_id': returnedPostId};
    } catch (e) {
      debugPrint("❌ [PostService] SAVE TOGGLE ERROR: $e");
      if (e is DioException) {
        debugPrint("❌ [PostService] Status: ${e.response?.statusCode}");
        debugPrint("❌ [PostService] Response: ${e.response?.data}");
        if (e.response?.statusCode == 401) {
          debugPrint("❌ [PostService] Unauthorized error");
        }
      }
      rethrow;
    }
  }

  Future<List<Post>> fetchSavedPosts() async {
    debugPrint('🚀 [PostService] fetchSavedPosts START');
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.get(
        "posts/saved/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ [PostService] SAVED POSTS SUCCESS: ${res.data}");

      final data = res.data['data'];
      final List<dynamic> postsJson = data['posts'] ?? data['results'] ?? [];

      final posts = postsJson
          .map((json) => Post.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      debugPrint('✅ [PostService] Fetched ${posts.length} saved posts');

      return posts;
    } catch (e) {
      debugPrint("❌ [PostService] FETCH SAVED POSTS ERROR: $e");
      if (e is DioException) {
        debugPrint("❌ [PostService] Status: ${e.response?.statusCode}");
        debugPrint("❌ [PostService] Response: ${e.response?.data}");
      }
      rethrow;
    }
  }

  Future<void> addComment(String postId, String text) async {
    final token = await TokenStorage.getAccessToken();

    try {
      debugPrint("💬 ADD COMMENT → $text");

      final res = await _dio.post(
        "posts/get-post/",
        data: {"post_id": postId, "comment": text},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ COMMENT RESPONSE: ${res.data}");
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ STATUS CODE: ${e.response?.statusCode}");
        debugPrint("❌ RESPONSE: ${e.response?.data}");
      } else {
        debugPrint("❌ ERROR: $e");
      }
    }
  }
}
