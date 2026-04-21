import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/cursor_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/paginated_response_model.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class PostService {
  late final Dio _dio;

  bool _isLoading = false;
  CursorModel? _nextCursor;
  String? _lastRequestKey;

  PostService() {
    var base = dotenv.env['BASE_URL']!.trim();
    if (!base.endsWith('/')) {
      base = '$base/';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
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

  Future<CreatePostResponse> createPost({
    required String caption,
    required String mediaPath,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final file = File(mediaPath);

      final formData = FormData.fromMap({
        "caption": caption,
        "file": await MultipartFile.fromFile(
          file.path,
          filename: file.path.replaceAll(r'\', '/').split('/').last,
        ),
      });

      final res = await _dio.post(
        "posts/create-post/",
        data: formData,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      print("✅ CREATE RESPONSE: ${res.data}");

      return CreatePostResponse.fromJson(res.data);
    } catch (e) {
      print("❌ CREATE ERROR: $e");
      rethrow;
    }
  }

  List<dynamic> _postsPayloadList(dynamic responseData) {
    if (responseData is! Map) {
      throw const FormatException('Expected JSON object');
    }

    final map = Map<String, dynamic>.from(responseData);
    final data = map['data'];

    if (data is Map && data['results'] is List) {
      return data['results'];
    }

    throw const FormatException("Invalid response format");
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

      final responseData = res.data['data'] ?? res.data;
      final posts =
          (responseData['posts'] as List<dynamic>?)
              ?.map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];

      final nextCursor = responseData['next_cursor'] != null
          ? CursorModel.fromJson(
              responseData['next_cursor'] as Map<String, dynamic>,
            )
          : null;

      final hasMore = responseData['has_more'] as bool? ?? true;

      if (!refresh) {
        _nextCursor = nextCursor;
      }

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
      final res = await _getWithRetry(
        "posts/get-post/",
        options: opts,
      );

      print("📡 FULL API RESPONSE: ${res.data}");

      final data = res.data['data'];

      if (data == null) {
        print("❌ Invalid response structure - no data field");
        return [];
      }

      List list;
      if (data['posts'] != null) {
        list = data['posts'];
      } else if (data['results'] != null) {
        list = data['results'];
      } else {
        print("❌ Invalid response structure - no posts or results field");
        return [];
      }

      print("📊 TOTAL POSTS FROM API: ${list.length}");

      return list.map((e) {
        final post = Post.fromJson(Map<String, dynamic>.from(e));

        print("✅ PARSED POST:");
        print("ID: ${post.id}");
        print("CAPTION: ${post.caption}");
        print("MEDIA: ${post.media}");
        print("❤️ Likes: ${post.likesCount}");
        print("💬 Comments: ${post.commentsCount}");
        print("👤 User: ${post.username}");
        print("🔔 Subscribed: ${post.isSubscribed}");

        return post;
      }).toList();
    } catch (e) {
      print("❌ GET POSTS ERROR: $e");
      if (e is DioError) {
        if (e.response?.statusCode == 401) {
          print("Unauthorized error");
          return [];
        }
        rethrow;
      }
      rethrow;
    }
  }

  void resetPagination() {
    _nextCursor = null;
    _lastRequestKey = null;
    _isLoading = false;
  }

  Future<bool> likePost(String postId) async {
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.post(
        "posts/like/toggle/",
        data: {
          "post_id": postId,
        },
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
