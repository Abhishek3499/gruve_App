import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import '../models/comment_model.dart';

class CommentService {
  late final Dio _dio;

  CommentService() {
    var base = dotenv.env['BASE_URL']!.trim();
    if (!base.endsWith('/')) {
      base = '$base/';
    }
    _dio = Dio(BaseOptions(baseUrl: base));
  }

  Future<List<Comment>> getComments(String postId) async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    try {
      final res = await _dio.get(
        "posts/comments/?post_id=$postId",
        options: opts,
      );

      debugPrint("💬 GET COMMENTS RESPONSE: ${res.data}");

      if (res.statusCode == 200 && res.data['success'] == true && res.data['data'] != null) {
        final commentResponse = CommentResponse.fromJson(res.data['data']);
        return commentResponse.results;
      }
      return [];
    } catch (e) {
      debugPrint("❌ GET COMMENTS ERROR: $e");
      return [];
    }
  }

  // CREATE COMMENT
  Future<bool> addComment(String postId, String body) async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    try {
      debugPrint("🚀 --- ADD COMMENT DEBUG ---");
      debugPrint("📡 REQUEST URL: posts/comments/");
      debugPrint("📦 PAYLOAD: {'post_id': '$postId', 'body': '$body'}");
      
      final res = await _dio.post(
        "posts/comments/",
        data: {
          "post_id": postId,
          "body": body,
        },
        options: opts,
      );

      debugPrint("✅ API SUCCESS: [${res.statusCode}]");
      debugPrint("📥 RESPONSE DATA: ${res.data}");
      debugPrint("🚀 ------------------------");
      
      return res.statusCode == 200 || res.statusCode == 201 || (res.data != null && res.data['success'] == true);
    } catch (e) {
      debugPrint("❌ --- ADD COMMENT ERROR ---");
      if (e is DioException) {
        debugPrint("🚨 DIO ERROR: ${e.message}");
        debugPrint("🚨 STATUS CODE: ${e.response?.statusCode}");
        debugPrint("🚨 RESPONSE DATA: ${e.response?.data}");
      } else {
        debugPrint("🚨 UNKNOWN ERROR: $e");
      }
      debugPrint("❌ -------------------------");
      return false;
    }
  }
}
