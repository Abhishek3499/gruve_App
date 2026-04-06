import 'dart:io';
import 'package:dio/dio.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class PostService {
  /// Same pattern as [ProfileService] / auth services: normalized base + relative paths.
  late final Dio _dio;

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

  // ✅ GET POSTS — same relative-path style as initial load; try alternates on 404.
  Future<List<Post>> getPosts() async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    try {
      final res = await _dio.get("posts/get-post/", options: opts);

      print("📡 FULL API RESPONSE: ${res.data}");

      final data = res.data['data'];

      if (data == null || data['results'] == null) {
        print("❌ Invalid response structure");
        return [];
      }

      final List list = data['results'];

      print("📊 TOTAL POSTS FROM API: ${list.length}");

      return list.map((e) {
        final post = Post.fromJson(Map<String, dynamic>.from(e));

        print("✅ PARSED POST:");
        print("ID: ${post.id}");
        print("CAPTION: ${post.caption}");
        print("MEDIA: ${post.media}");

        return post;
      }).toList();
    } catch (e) {
      print("❌ GET POSTS ERROR: $e");
      rethrow;
    }
  }

  Future<void> likePost(String postId) async {
    final token = await TokenStorage.getAccessToken();

    try {
      final res = await _dio.post(
        "posts/like/toggle/", // ✅ endpoint
        data: {
          "post_id": postId, // ✅ body me bhejna hai
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("❤️ LIKE SUCCESS: ${res.data}");
    } catch (e) {
      print("❌ LIKE ERROR: $e");
    }
  }
}
