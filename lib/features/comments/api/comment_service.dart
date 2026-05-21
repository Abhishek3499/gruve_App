import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import '../models/comment_model.dart';

class _CommentCacheEntry {
  const _CommentCacheEntry(this.comments, this.createdAt);

  final List<Comment> comments;
  final DateTime createdAt;

  bool get isFresh =>
      DateTime.now().difference(createdAt) < const Duration(minutes: 2);
}

class CommentService {
  late final Dio _dio;
  static final Map<String, _CommentCacheEntry> _cache = {};
  static final Map<String, Future<List<Comment>>> _inFlight = {};

  CommentService() {
    _dio = AppDio.create(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    );
  }

  Future<List<Comment>> getComments(
    String postId, {
    bool forceRefresh = false,
  }) async {
    final cached = _cache[postId];
    if (!forceRefresh && cached != null && cached.isFresh) {
      return cached.comments;
    }

    final inFlight = _inFlight[postId];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _fetchComments(postId);
    _inFlight[postId] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(postId);
    }
  }

  Future<List<Comment>> _fetchComments(String postId) async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    try {
      final res = await _dio.get(
        "posts/comments/",
        queryParameters: {'post_id': postId},
        options: opts,
      );

      if (res.statusCode == 200 &&
          res.data['success'] == true &&
          res.data['data'] != null) {
        final commentResponse = CommentResponse.fromJson(res.data['data']);
        final comments = List<Comment>.unmodifiable(commentResponse.results);
        _cache[postId] = _CommentCacheEntry(comments, DateTime.now());
        return comments;
      }
      return [];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        debugPrint("⏱️ GET COMMENTS TIMEOUT for post $postId");
      } else {
        debugPrint("❌ GET COMMENTS ERROR: ${e.message}");
      }
      return [];
    } catch (e) {
      debugPrint("❌ GET COMMENTS UNEXPECTED ERROR: $e");
      return [];
    }
  }

  // Returns the new Comment on success, null on failure
  Future<Comment?> addComment(String postId, String body) async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(headers: {"Authorization": "Bearer $token"});

    try {
      final res = await _dio.post(
        "posts/comments/",
        data: {"post_id": postId, "body": body},
        options: opts,
      );

      debugPrint("✅ ADD COMMENT [${res.statusCode}]: ${res.data}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data;
        final commentJson = data?['data'] ?? data?['comment'];
        if (commentJson is Map<String, dynamic> && commentJson.containsKey('id')) {
          return Comment.fromJson(commentJson);
        }
        // API succeeded but no comment object — return local placeholder
        return Comment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          body: body,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          user: CommentUser(id: '', username: 'You', isSubscribed: false),
        );
      }
      return null;
    } on DioException catch (e) {
      debugPrint("❌ ADD COMMENT ERROR: ${e.message} [${e.response?.statusCode}]");
      return null;
    } catch (e) {
      debugPrint("❌ ADD COMMENT UNEXPECTED ERROR: $e");
      return null;
    }
  }

  static void invalidatePost(String postId) {
    _cache.remove(postId);
  }
}
