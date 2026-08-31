import 'dart:async';
import 'package:dio/dio.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/datasource/token_storage.dart';

import 'package:gruve_app/features/comments/domain/entities/comment_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class _CommentCacheEntry {
  const _CommentCacheEntry(this.comments, this.createdAt);

  final List<Comment> comments;
  final DateTime createdAt;

  bool get isFresh =>
      DateTime.now().difference(createdAt) < const Duration(minutes: 2);
}

class CommentService {
  CommentService() {
    _dio = AppDio.getInstance();
  }

  late final Dio _dio;
  static final Map<String, _CommentCacheEntry> _cache = {};
  static final Map<String, Future<List<Comment>>> _inFlight = {};

  Future<List<Comment>> getComments(
    String postId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      invalidatePost(postId);
    }
    final cached = _cache[postId];
    if (!forceRefresh && cached != null && cached.isFresh) {
      return cached.comments;
    }

    final inFlight = _inFlight[postId];
    if (inFlight != null) return inFlight;

    final future = _fetchComments(postId, forceRefresh: forceRefresh);
    _inFlight[postId] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(postId);
    }
  }

  Future<List<Comment>> _fetchComments(
    String postId, {
    bool forceRefresh = false,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final opts = Options(
      headers: {'Authorization': 'Bearer $token'},
      extra: forceRefresh ? {'skipCache': true, 'bypassCache': true} : null,
    );

    try {
      final res = await _dio.get(
        ApiConstants.comments,
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
    } catch (_) {
      return [];
    }
  }

  Future<Comment?> addComment(String postId, String body) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated (token is null or empty)');
    }
    final opts = Options();
    final payload = {'post_id': postId, 'body': body};

    Comment? comment;
    try {
      comment = await _tryAddComment(
        endpoint: ApiConstants.comments,
        payload: payload,
        options: opts,
        body: body,
      );
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          rethrow;
        }
      }

      AppLogger.d('[CommentService] First comment attempt failed: $e. Retrying in 1s...');
      await Future<void>.delayed(const Duration(seconds: 1));

      comment = await _tryAddComment(
        endpoint: ApiConstants.comments,
        payload: payload,
        options: opts,
        body: body,
      );
    }

    if (comment != null) {
      invalidatePost(postId);
    }
    return comment;
  }

  Future<Comment?> _tryAddComment({
    required String endpoint,
    required Map<String, dynamic> payload,
    required Options options,
    required String body,
  }) async {
    final requestOptions = options.copyWith(
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      extra: {...?options.extra, 'skipCache': true, 'bypassCache': true},
    );
    final res = await _dio.post(
      endpoint,
      data: payload,
      options: requestOptions,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final commentJson = _extractCommentJson(res.data);

      if (commentJson != null && commentJson.containsKey('id')) {
        return Comment.fromJson(commentJson);
      }

      return Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        body: body,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        user: CommentUser(id: '', username: 'You', isSubscribed: false),
      );
    }

    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
      message: 'Failed to add comment: server returned status ${res.statusCode}',
    );
  }

  Map<String, dynamic>? _extractCommentJson(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    final direct = map['comment'];
    if (direct is Map) return Map<String, dynamic>.from(direct);

    final nestedData = map['data'];
    if (nestedData is Map) {
      final nestedMap = Map<String, dynamic>.from(nestedData);
      final nestedComment = nestedMap['comment'];
      if (nestedComment is Map) return Map<String, dynamic>.from(nestedComment);
      if (nestedMap.containsKey('id')) return nestedMap;
    }

    if (map.containsKey('id')) return map;
    return null;
  }

  static void invalidatePost(String postId) {
    _cache.remove(postId);
    unawaited(CacheInvalidationService().onCommentAdded(postId));
  }
}
