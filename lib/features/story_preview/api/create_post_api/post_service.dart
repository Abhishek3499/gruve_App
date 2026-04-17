import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/cursor_model.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/paginated_response_model.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class PostService {
  /// Same pattern as [ProfileService] / auth services: normalized base + relative paths.
  late final Dio _dio;

  // Pagination state
  bool _isLoading = false;
  CursorModel? _nextCursor;
  String? _lastRequestKey;

  PostService() {
    var base = dotenv.env['BASE_URL']!.trim();
    if (!base.endsWith('/')) {
      base = '$base/';
    }
    _dio = Dio(BaseOptions(baseUrl: base));
  }

  // ✅ CREATE POST
  Future<CreatePostResponse> createPost({
    required String caption,
    required String mediaPath,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();

      File file = File(mediaPath);

      FormData formData = FormData.fromMap({
        "caption": caption,
        "file": await MultipartFile.fromFile(
          file.path,
          filename: file.path.replaceAll(r'\', '/').split('/').last,
        ),
      });

      final res = await _dio.post(
        "posts/create-post/",
        data: formData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
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

    throw FormatException("Invalid response format");
  }

  // ✅ GET POSTS WITH CURSOR PAGINATION
  Future<PaginatedPostsResponse> getPaginatedPosts({
    CursorModel? cursor,
    int limit = 10,
    bool refresh = false,
  }) async {
    final isInitialLoad = cursor == null || !cursor!.isValid;

    // Prevent duplicate requests
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

      // Add cursor parameters if available
      if (cursor?.isValid == true) {
        queryParams.addAll(cursor!.toJson());
        debugPrint(
          '📍 Next Cursor: {created_at: ${cursor!.createdAt}, id: ${cursor!.id}}',
        );
      }

      final res = await _dio.get(
        "posts/get-post/",
        queryParameters: queryParams,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      // Handle both nested data structure and direct response structure
      final responseData = res.data['data'] ?? res.data;
      
      final posts =
          (responseData['posts'] as List<dynamic>?)
              ?.map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];

      final nextCursor = responseData['next_cursor'] != null
          ? CursorModel.fromJson(responseData['next_cursor'] as Map<String, dynamic>)
          : null;

      final hasMore = responseData['has_more'] as bool? ?? true;

      // Update cursor for next request
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
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    } finally {
      _isLoading = false;
    }
  }

  // ✅ GET POSTS — same relative-path style as initial load; try alternates on 404.
  Future<List<Post>> getPosts() async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    try {
      final res = await _dio.get("posts/get-post/", options: opts);

      print("📡 FULL API RESPONSE: ${res.data}");

      final data = res.data['data'];

      if (data == null) {
        print("❌ Invalid response structure - no data field");
        return [];
      }

      // Handle both direct posts array and nested structure
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
          // Handle unauthorized error
          print("Unauthorized error");
          return []; // Return empty list instead of null
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  // Reset pagination state
  void resetPagination() {
    _nextCursor = null;
    _lastRequestKey = null;
    _isLoading = false;
  }

  Future<bool> likePost(String postId) async {
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.post(
        "posts/like/toggle/", // endpoint
        data: {
          "post_id": postId, // body me bhejna hai
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint("✅ LIKE SUCCESS: ${res.data}");
      return true;
    } catch (e) {
      debugPrint("❌ LIKE ERROR: $e");
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          // Handle unauthorized error
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
        "posts/get-post/", // ⚠️ endpoint check kar lena
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
