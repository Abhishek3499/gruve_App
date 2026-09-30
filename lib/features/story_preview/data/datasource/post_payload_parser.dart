import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';

/// Pure parsing/validation helpers for post API payloads (no network access).
class PostPayloadParser {
  PostPayloadParser._();

  static Post? extractPostFromProfilePayload(dynamic payload, String postId) {
    final root = payload is Map ? (payload['data'] ?? payload) : null;
    if (root is! Map) return null;

    final rootMap = Map<String, dynamic>.from(root);
    final postsRoot = rootMap['posts'];
    if (postsRoot is! Map) return null;

    final postsMap = Map<String, dynamic>.from(postsRoot);
    for (final tabKey in ['all', 'trending', 'liked', 'likes']) {
      final tab = postsMap[tabKey];
      if (tab is! Map) continue;
      final tabMap = Map<String, dynamic>.from(tab);
      final results = tabMap['results'];
      if (results is! List) continue;

      for (final item in results) {
        if (item is! Map) continue;
        final itemMap = Map<String, dynamic>.from(item);
        final itemId = _readPostId(
          itemMap['id'] ?? itemMap['post_id'] ?? itemMap['postId'],
        );
        if (itemId != null && _idsMatch(itemId, postId)) {
          if (rootMap['user'] is Map) {
            final userMap = Map<String, dynamic>.from(rootMap['user'] as Map);
            if (itemMap['profile_picture'] == null &&
                itemMap['profilePicture'] == null) {
              final avatar = userMap['profile_picture'] ?? userMap['avatar'];
              if (avatar != null && avatar.toString().trim().isNotEmpty) {
                itemMap['profile_picture'] = avatar;
              }
            }
            if (itemMap['username'] == null ||
                itemMap['username'].toString().trim().isEmpty) {
              final username = userMap['username']?.toString();
              if (username != null && username.isNotEmpty) {
                itemMap['username'] = username;
              }
            }
            if (itemMap['user'] == null && userMap.isNotEmpty) {
              itemMap['user'] = userMap;
            }
          }

          return Post.fromJson(itemMap);
        }
      }
    }
    return null;
  }

  static Post? tryParsePostResponse(dynamic responseData, String postId) {
    try {
      return _postFromResponseData(responseData, postId);
    } catch (e) {
      AppLogger.warning(
        'PostService',
        'post_response_parse_failed',
        data: {'postId': postId, 'error': e.toString()},
      );
      return null;
    }
  }

  static bool isCompleteFetchedPost(Post? post, String expectedId) {
    if (post == null) return false;
    if (post.id.isNotEmpty && !_idsMatch(post.id, expectedId)) return false;
    if (post.isVideo) {
      final media = post.media.trim();
      return media.isNotEmpty &&
          (media.startsWith('http://') || media.startsWith('https://'));
    }
    return post.hasPlayableMedia;
  }

  /// Resolves the requested [postId] from API payloads that may be a single post
  /// or a paginated list (never parse feed wrappers as posts).
  static Post _postFromResponseData(dynamic responseData, String postId) {
    if (responseData is! Map) {
      throw Exception('Post not found or invalid format');
    }

    final map = Map<String, dynamic>.from(responseData);

    if (_mapLooksLikePost(map)) {
      final directId = _readPostId(
        map['id'] ?? map['post_id'] ?? map['postId'],
      );
      if (directId == null || _idsMatch(directId, postId)) {
        return Post.fromJson(map);
      }
    }

    final singlePost = map['post'];
    if (singlePost is Map) {
      return Post.fromJson(Map<String, dynamic>.from(singlePost));
    }

    for (final listKey in ['posts', 'results', 'items']) {
      final list = map[listKey];
      if (list is! List || list.isEmpty) continue;

      for (final item in list) {
        if (item is! Map) continue;
        final itemMap = Map<String, dynamic>.from(item);
        final itemId = _readPostId(
          itemMap['id'] ?? itemMap['post_id'] ?? itemMap['postId'],
        );
        if (itemId != null && _idsMatch(itemId, postId)) {
          return Post.fromJson(itemMap);
        }
      }

      if (list.length == 1 && list.first is Map) {
        return Post.fromJson(Map<String, dynamic>.from(list.first as Map));
      }
    }

    throw Exception('Post $postId not found in response');
  }

  static bool _mapLooksLikePost(Map<String, dynamic> map) {
    return map.containsKey('id') ||
        map.containsKey('post_id') ||
        map.containsKey('postId') ||
        map.containsKey('media_url') ||
        map.containsKey('mediaUrl') ||
        map.containsKey('media') ||
        map.containsKey('file') ||
        map.containsKey('video_url');
  }

  static bool _idsMatch(String a, String b) {
    final na = a.startsWith('pst_') ? a.substring(4) : a;
    final nb = b.startsWith('pst_') ? b.substring(4) : b;
    return na == nb;
  }

  static String? _readPostId(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('pst_')) return value.substring(4);
    return value;
  }
}
