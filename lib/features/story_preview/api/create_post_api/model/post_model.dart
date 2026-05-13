import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreatePostResponse {
  final bool success;
  final String message;

  CreatePostResponse({required this.success, required this.message});

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) {
    debugPrint("Create response json: $json");

    return CreatePostResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
    );
  }
}

class Post {
  final String id;
  final String caption;
  final String media;
  final String userId;
  final String mediaType;

  int likesCount;
  int commentsCount;
  bool isLiked;

  String username;
  bool isSubscribed;
  String profilePicture;
  bool hasActiveStory;

  Post({
    required this.id,
    required this.caption,
    required this.media,
    required this.userId,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.username,
    required this.isSubscribed,
    required this.profilePicture,
    this.mediaType = 'image',
    this.hasActiveStory = false,
  });

  bool get isVideo =>
      mediaType.toLowerCase().trim() == 'video' ||
      mediaUrlLooksLikeVideo(media);

  /// True when [url] looks like a streamable video (path/query tolerant).
  static bool mediaUrlLooksLikeVideo(String url) {
    final trimmed = url.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    final path = trimmed.split('?').first.split('#').first;
    const videoHints = <String>[
      '.mp4',
      '.mov',
      '.m4v',
      '.webm',
      '.mkv',
      '.avi',
      '.m3u8',
      '.3gp',
    ];
    for (final h in videoHints) {
      if (path.contains(h)) return true;
    }
    return false;
  }

  static bool _mimeLooksLikeVideo(String? raw) {
    if (raw == null) return false;
    return raw.toLowerCase().trim().startsWith('video/');
  }

  /// Resolves API quirks: numeric enums, mime types, nested `media` objects,
  /// and avoids using top-level `type` when it is clearly not a media kind.
  static String _resolveMediaType(Map<String, dynamic> json, String mediaUrl) {
    if (json['is_video'] == true || json['isVideo'] == true) {
      return 'video';
    }

    final nested = json['media'];
    if (nested is Map) {
      final nm = Map<String, dynamic>.from(Map<Object?, Object?>.from(nested));
      final nestedType = nm['type'] ?? nm['media_type'] ?? nm['mediaType'];
      final nestedStr = nestedType?.toString().toLowerCase().trim();
      if (nestedStr == 'video' ||
          nestedStr == 'image' ||
          nestedStr == 'carousel') {
        if (kDebugMode) {
          debugPrint('🎥 [Post] nested media.type=$nestedStr');
        }
        if (nestedStr == 'video') return 'video';
      }
    }

    for (final key in [
      'media_type',
      'mediaType',
      'mime_type',
      'content_type',
    ]) {
      final raw = json[key];
      if (raw == null) continue;
      final s = raw.toString().toLowerCase().trim();
      if (s == 'video' || s == 'image' || s == 'carousel') return s;
      // Some backends use small integers for media_kind (2 = video is common).
      if ((key == 'media_type' || key == 'mediaType') &&
          (s == '2' || s == '3')) {
        return 'video';
      }
      if ((key == 'media_type' || key == 'mediaType') &&
          (s == '1' || s == '0')) {
        return 'image';
      }
      if (_mimeLooksLikeVideo(s)) return 'video';
      if (s.contains('video/')) return 'video';
    }

    final postType = json['type']?.toString().toLowerCase().trim();
    if (postType != null && postType.isNotEmpty) {
      const videoish = {'video', 'reel', 'clip', 'short', 'shorts', 'igtv'};
      if (videoish.contains(postType) || postType.contains('video')) {
        if (kDebugMode) {
          debugPrint('🎥 [Post] post type hints video: $postType');
        }
        return 'video';
      }
      if (postType == 'image' ||
          postType == 'photo' ||
          postType == 'carousel') {
        return postType == 'carousel' ? 'carousel' : 'image';
      }
    }

    if (mediaUrlLooksLikeVideo(mediaUrl)) return 'video';

    return 'image';
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final mediaUrl = _extractPrimaryMediaUrl(json);

    final mediaType = _resolveMediaType(json, mediaUrl);

    if (kDebugMode) {
      final kind = mediaType == 'video' || mediaUrlLooksLikeVideo(mediaUrl)
          ? '🎥 video'
          : '🖼 image';
      debugPrint(
        '📡 [Post.fromJson] $kind detected id=${json['id']} mediaType=$mediaType url=${mediaUrl.length > 80 ? '${mediaUrl.substring(0, 80)}…' : mediaUrl}',
      );
    }

    return Post(
      id: json['id']?.toString() ?? "",
      caption: json['caption']?.toString() ?? "",
      media: mediaUrl,
      mediaType: mediaType == 'video' || mediaUrlLooksLikeVideo(mediaUrl)
          ? 'video'
          : mediaType,
      userId:
          json['user']?['id']?.toString() ??
          json['user_id']?.toString() ??
          json['author_id']?.toString() ??
          "unknown",
      likesCount: json['likes_count'] ?? json['like_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? json['liked'] ?? false,
      username:
          json['user']?['username']?.toString() ??
          json['username']?.toString() ??
          "unknown",
      isSubscribed: json['user']?['is_subscribed'] ?? false,
      profilePicture: _normalizeUrl(
        json['user']?['profile_picture'] ?? json['profile_picture'] ?? "",
      ),
      hasActiveStory:
          json['user']?['has_active_story'] ??
          json['has_active_story'] ??
          false,
    );
  }

  /// Picks the best media URL whether the API returns a string or nested map.
  static String _extractPrimaryMediaUrl(Map<String, dynamic> json) {
    dynamic raw =
        json['media_url'] ??
        json['mediaUrl'] ??
        json['file'] ??
        json['video_url'] ??
        json['videoUrl'] ??
        json['url'];

    String normalized = _normalizeUrl(raw ?? '');
    if (normalized.isEmpty && json['media'] is String) {
      normalized = _normalizeUrl(json['media']);
    }
    if (normalized.isEmpty && json['media'] is Map) {
      final m = Map<String, dynamic>.from(
        Map<Object?, Object?>.from(json['media'] as Map),
      );
      raw = m['url'] ?? m['src'] ?? m['file'] ?? m['media_url'];
      normalized = _normalizeUrl(raw ?? '');
    }

    return normalized;
  }

  static String _normalizeUrl(dynamic rawValue) {
    final value = rawValue?.toString().trim() ?? "";

    if (value.isEmpty || value.toLowerCase() == 'null') {
      return "";
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    final baseUrl = (dotenv.env['BASE_URL'] ?? "").trim();
    if (baseUrl.isEmpty) {
      return value;
    }

    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null) {
      return value;
    }

    final normalizedRelativePath = value.startsWith('/') ? value : '/$value';
    return baseUri.resolve(normalizedRelativePath).toString();
  }
}
