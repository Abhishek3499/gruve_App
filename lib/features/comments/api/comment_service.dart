import 'package:dio/dio.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/token_storage.dart';

import '../models/comment_model.dart';

class _CommentCacheEntry {
  const _CommentCacheEntry(this.comments, this.createdAt);

  final List<Comment> comments;
  final DateTime createdAt;

  bool get isFresh =>
      DateTime.now().difference(createdAt) < const Duration(minutes: 2);
}

class CommentService {
  CommentService() {
    _dio = AppDio.create(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    );

    var baseUrl = EnvironmentConfig.baseUrl.trim();
    if (baseUrl.isNotEmpty && !baseUrl.endsWith('/')) {
      baseUrl = '$baseUrl/';
    }

    _writeDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
  }

  late final Dio _dio;
  late final Dio _writeDio;
  static final Map<String, _CommentCacheEntry> _cache = {};
  static final Map<String, Future<List<Comment>>> _inFlight = {};

  Future<List<Comment>> getComments(
    String postId, {
    bool forceRefresh = false,
  }) async {
    final cached = _cache[postId];
    if (!forceRefresh && cached != null && cached.isFresh) {
      return cached.comments;
    }

    final inFlight = _inFlight[postId];
    if (inFlight != null) return inFlight;

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
    final opts = Options(headers: {'Authorization': 'Bearer $token'});

    try {
      final res = await _dio.get(
        'posts/comments/',
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
    final opts = Options(headers: {'Authorization': 'Bearer $token'});

    final payloads = <Map<String, dynamic>>[
      {'post_id': postId, 'body': body},
      {'post': postId, 'body': body},
      {'post_id': postId, 'comment': body},
      {'post': postId, 'comment': body},
      {'post_id': postId, 'text': body},
      {'post': postId, 'text': body},
    ];

    for (var i = 0; i < payloads.length; i++) {
      final primary = await _tryAddComment(
        endpoint: 'posts/comments/',
        payload: payloads[i],
        options: opts,
        body: body,
      );
      if (primary != null) return primary;
    }

    return _tryAddComment(
      endpoint: 'posts/get-post/',
      payload: {'post_id': postId, 'comment': body},
      options: opts,
      body: body,
    );
  }

  Future<Comment?> _tryAddComment({
    required String endpoint,
    required Map<String, dynamic> payload,
    required Options options,
    required String body,
  }) async {
    try {
      final requestOptions = options.copyWith(
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        extra: {...?options.extra, 'skipCache': true, 'bypassCache': true},
      );
      final res = await _writeDio.post(
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

      return null;
    } catch (_) {
      return null;
    }
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
  }
}
