import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class PostService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL']!));

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
          filename: file.path.split('/').last,
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

  // ✅ GET POSTS
  Future<List<Post>> getPosts() async {
    try {
      final token = await TokenStorage.getAccessToken();

      final res = await _dio.get(
        "posts/get-posts/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      List postsJson = res.data['data'];

      return postsJson.map((e) => Post.fromJson(e)).toList();
    } catch (e) {
      print("❌ GET ERROR: $e");
      rethrow;
    }
  }
}
