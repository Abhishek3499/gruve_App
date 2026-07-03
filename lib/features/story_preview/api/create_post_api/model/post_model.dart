import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class CreatePostResponse {
  final bool success;
  final String message;
  final Post? data;

  CreatePostResponse({required this.success, required this.message, this.data});

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) {
    AppLogger.d("Create response json: $json");

    return CreatePostResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
      data: json['data'] != null
          ? Post.fromJson(Map<String, dynamic>.from(json['data']))
          : null,
    );
  }
}

class Post {
  final String id;
  final String caption;
  final String media;
  final String thumbnailUrl;
  final String userId;
  final String mediaType;

  int likesCount;
  int commentsCount;
  int sharesCount;
  bool isLiked;

  String username;
  bool isSubscribed;
  String profilePicture;
  bool hasActiveStory;

  final List<TaggedUser> taggedUsers;

  Post({
    required this.id,
    required this.caption,
    required this.media,
    this.thumbnailUrl = '',
    required this.userId,
    required this.likesCount,
    required this.commentsCount,
    this.sharesCount = 0,
    required this.isLiked,
    required this.username,
    required this.isSubscribed,
    required this.profilePicture,
    this.mediaType = 'image',
    this.hasActiveStory = false,
    this.taggedUsers = const [],
  });

  /// Poster shown while a video buffer initializes (TikTok-style instant frame).
  String get feedPosterUrl {
    final thumb = thumbnailUrl.trim();
    if (thumb.isNotEmpty && !mediaUrlLooksLikeVideo(thumb)) return thumb;
    return '';
  }

  /// Thumbnail for profile grids and link previews (Instagram-style).
  String get gridPreviewUrl {
    if (feedPosterUrl.isNotEmpty) return feedPosterUrl;
    if (!isVideo) return media.trim();
    return '';
  }

  /// Whether this post can appear in the home feed (has a loadable network URL).
  bool get isFeedEligible {
    return feedMediaUrl.isNotEmpty;
  }

  /// Best URL for rendering/playing in the home feed (media → poster for images).
  String get feedMediaUrl {
    for (final url in [media.trim(), playbackMediaUrl.trim()]) {
      if (_isSupportedNetworkUrl(url)) return url;
    }

    if (!isVideo && !mediaUrlLooksLikeVideo(media)) {
      for (final url in [thumbnailUrl.trim(), gridPreviewUrl.trim()]) {
        if (_isSupportedNetworkUrl(url)) return url;
      }
    }

    // List payloads sometimes ship only a poster for videos — still show the slot.
    if (isVideo && _isSupportedNetworkUrl(thumbnailUrl.trim())) {
      return thumbnailUrl.trim();
    }

    return '';
  }

  static bool _isSupportedNetworkUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

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
        AppLogger.d('🎥 [Post] nested media.type=$nestedStr');

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
        AppLogger.d('🎥 [Post] post type hints video: $postType');

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
      AppLogger.d(
        '📡 [Post.fromJson] $kind detected id=${json['id']} mediaType=$mediaType url=${mediaUrl.length > 80 ? '${mediaUrl.substring(0, 80)}…' : mediaUrl}',
      );
    }

    final rawTagged =
        json['tagged_users'] as List<dynamic>? ??
        json['taggedUsers'] as List<dynamic>? ??
        [];
    final taggedList = rawTagged
        .map((e) => TaggedUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawId =
        json['id']?.toString() ??
        json['post_id']?.toString() ??
        json['postId']?.toString() ??
        "";
    final cleanId = rawId.startsWith('pst_') ? rawId.substring(4) : rawId;

    return Post(
      id: cleanId,
      caption:
          json['caption']?.toString() ??
          json['text']?.toString() ??
          json['content']?.toString() ??
          "",
      media: mediaUrl,
      thumbnailUrl: _extractThumbnailUrl(json),
      mediaType: mediaType == 'video' || mediaUrlLooksLikeVideo(mediaUrl)
          ? 'video'
          : mediaType,
      userId:
          (json['user'] is Map ? json['user']['id']?.toString() : null) ??
          (json['creator'] is Map ? json['creator']['id']?.toString() : null) ??
          (json['author'] is Map ? json['author']['id']?.toString() : null) ??
          json['user_id']?.toString() ??
          json['creator_id']?.toString() ??
          json['author_id']?.toString() ??
          json['userId']?.toString() ??
          json['creatorId']?.toString() ??
          "unknown",
      likesCount: _readIntCount(json, const [
        'likes_count',
        'like_count',
        'likesCount',
        'likes',
        'total_likes',
      ]),
      commentsCount: _readIntCount(json, const [
        'comments_count',
        'comment_count',
        'commentsCount',
        'comments',
        'total_comments',
      ]),
      sharesCount: _readIntCount(json, const [
        'shares_count',
        'share_count',
        'sharesCount',
        'shares',
        'total_shares',
      ]),
      isLiked: json['is_liked'] ?? json['liked'] ?? json['isLiked'] ?? false,
      username:
          (json['user'] is Map
              ? (json['user']['username']?.toString() ??
                    json['user']['user_name']?.toString() ??
                    json['user']['name']?.toString() ??
                    json['user']['fullName']?.toString() ??
                    json['user']['full_name']?.toString())
              : null) ??
          (json['user'] is String ? json['user']?.toString() : null) ??
          (json['creator'] is Map
              ? (json['creator']['username']?.toString() ??
                    json['creator']['user_name']?.toString() ??
                    json['creator']['name']?.toString() ??
                    json['creator']['fullName']?.toString() ??
                    json['creator']['full_name']?.toString())
              : null) ??
          (json['creator'] is String ? json['creator']?.toString() : null) ??
          (json['author'] is Map
              ? (json['author']['username']?.toString() ??
                    json['author']['user_name']?.toString() ??
                    json['author']['name']?.toString() ??
                    json['author']['fullName']?.toString() ??
                    json['author']['full_name']?.toString())
              : null) ??
          (json['author'] is String ? json['author']?.toString() : null) ??
          json['username']?.toString() ??
          json['user_name']?.toString() ??
          json['creator_username']?.toString() ??
          json['creatorUsername']?.toString() ??
          "unknown",
      isSubscribed:
          (json['user'] is Map ? json['user']['is_subscribed'] : null) ??
          (json['creator'] is Map ? json['creator']['is_subscribed'] : null) ??
          json['is_subscribed'] ??
          json['isSubscribed'] ??
          false,
      profilePicture: _normalizeUrl(
        (json['user'] is Map
                ? (json['user']['profile_picture'] ??
                      json['user']['profilePicture'] ??
                      json['user']['profile_image'] ??
                      json['user']['profileImage'] ??
                      json['user']['avatar'] ??
                      json['user']['avatar_url'])
                : null) ??
            (json['creator'] is Map
                ? (json['creator']['profile_picture'] ??
                      json['creator']['profilePicture'] ??
                      json['creator']['profile_image'] ??
                      json['creator']['profileImage'] ??
                      json['creator']['avatar'] ??
                      json['creator']['avatar_url'])
                : null) ??
            (json['author'] is Map
                ? (json['author']['profile_picture'] ??
                      json['author']['profilePicture'] ??
                      json['author']['profile_image'] ??
                      json['author']['profileImage'] ??
                      json['author']['avatar'] ??
                      json['author']['avatar_url'])
                : null) ??
            json['profile_picture'] ??
            json['profilePicture'] ??
            json['profile_image'] ??
            json['profileImage'] ??
            json['avatar'] ??
            json['avatar_url'] ??
            "",
      ),
      hasActiveStory:
          json['user']?['has_active_story'] ??
          json['creator']?['has_active_story'] ??
          json['has_active_story'] ??
          json['hasActiveStory'] ??
          false,
      taggedUsers: taggedList,
    );
  }

  static String _extractThumbnailUrl(Map<String, dynamic> json) {
    dynamic raw =
        json['thumbnail_url'] ??
        json['thumbnailUrl'] ??
        json['thumbnail'] ??
        json['image'] ??
        json['poster_url'] ??
        json['posterUrl'] ??
        json['poster'] ??
        json['cover_url'] ??
        json['coverUrl'] ??
        json['cover'] ??
        json['thumb'] ??
        json['preview_image'] ??
        json['previewImage'] ??
        json['preview_url'] ??
        json['previewUrl'] ??
        json['image_url'] ??
        json['imageUrl'] ??
        json['video_thumbnail'] ??
        json['videoThumbnail'];

    var normalized = _normalizeUrl(raw ?? '');
    if (normalized.isEmpty) {
      for (final nestedKey in ['media', 'video', 'file']) {
        final nested = json[nestedKey];
        if (nested is! Map) continue;
        final m = Map<String, dynamic>.from(Map<Object?, Object?>.from(nested));
        raw =
            m['thumbnail_url'] ??
            m['thumbnailUrl'] ??
            m['thumbnail'] ??
            m['poster'] ??
            m['poster_url'] ??
            m['cover'] ??
            m['cover_url'] ??
            m['preview'] ??
            m['preview_image'] ??
            m['image_url'] ??
            m['image'];
        normalized = _normalizeUrl(raw ?? '');
        if (normalized.isNotEmpty) break;
      }
    }

    if (mediaUrlLooksLikeVideo(normalized)) return '';
    return normalized;
  }

  /// Picks the best media URL whether the API returns a string or nested map.
  static String _extractPrimaryMediaUrl(Map<String, dynamic> json) {
    dynamic raw =
        json['media_url'] ??
        json['mediaUrl'] ??
        json['file'] ??
        json['video_url'] ??
        json['videoUrl'] ??
        json['url'] ??
        json['image_url'] ??
        json['imageUrl'] ??
        json['image'] ??
        json['thumbnail_url'] ??
        json['thumbnailUrl'] ??
        json['preview_url'] ??
        json['previewUrl'];

    String normalized = _normalizeUrl(raw ?? '');
    if (normalized.isEmpty && json['media'] is String) {
      normalized = _normalizeUrl(json['media']);
    }
    if (normalized.isEmpty && json['media'] is Map) {
      final m = Map<String, dynamic>.from(
        Map<Object?, Object?>.from(json['media'] as Map),
      );
      raw =
          m['url'] ??
          m['src'] ??
          m['file'] ??
          m['path'] ??
          m['link'] ??
          m['media_url'] ??
          m['mediaUrl'] ??
          m['video_url'] ??
          m['videoUrl'];
      normalized = _normalizeUrl(raw ?? '');
    }

    if (normalized.isEmpty && json['media'] is List) {
      final items = json['media'] as List;
      for (final item in items) {
        if (item is String) {
          normalized = _normalizeUrl(item);
        } else if (item is Map) {
          final m = Map<String, dynamic>.from(
            Map<Object?, Object?>.from(item),
          );
          raw =
              m['url'] ??
              m['src'] ??
              m['file'] ??
              m['media_url'] ??
              m['mediaUrl'] ??
              m['video_url'] ??
              m['videoUrl'];
          normalized = _normalizeUrl(raw ?? '');
        }
        if (normalized.isNotEmpty) break;
      }
    }

    if (normalized.isEmpty && json['video'] != null) {
      final video = json['video'];
      if (video is String) {
        normalized = _normalizeUrl(video);
      } else if (video is Map) {
        final m = Map<String, dynamic>.from(
          Map<Object?, Object?>.from(video),
        );
        raw =
            m['url'] ??
            m['src'] ??
            m['file'] ??
            m['media_url'] ??
            m['mediaUrl'] ??
            m['video_url'] ??
            m['videoUrl'];
        normalized = _normalizeUrl(raw ?? '');
      }
    }

    return normalized;
  }

  static String normalizeMediaUrl(String raw) => _normalizeUrl(raw);

  static String _normalizeUrl(dynamic rawValue) {
    final value = rawValue?.toString().trim() ?? "";

    if (value.isEmpty || value.toLowerCase() == 'null') {
      return "";
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    final baseUrl = EnvironmentConfig.baseUrl.trim();
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

  static int _readIntCount(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];
      if (raw is int) return raw;
      if (raw is String) {
        final parsed = int.tryParse(raw.trim());
        if (parsed != null) return parsed;
      }
    }

    for (final nestedKey in ['stats', 'engagement', 'counts', 'metadata']) {
      final nested = json[nestedKey];
      if (nested is! Map) continue;
      final map = Map<String, dynamic>.from(Map<Object?, Object?>.from(nested));
      for (final key in keys) {
        final raw = map[key];
        if (raw is int) return raw;
        if (raw is String) {
          final parsed = int.tryParse(raw.trim());
          if (parsed != null) return parsed;
        }
      }
    }

    return 0;
  }

  /// Best URL for full-screen playback (media first, then poster/thumbnail).
  String get playbackMediaUrl {
    final primary = media.trim();
    if (primary.isNotEmpty) return primary;
    return gridPreviewUrl;
  }

  bool get hasPlayableMedia {
    final url = playbackMediaUrl.trim();
    return url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  String resolveUsername({String? fallback}) {
    final name = username.trim();
    if (name.isNotEmpty && name != 'unknown') return name;
    final fb = fallback?.trim() ?? '';
    if (fb.isNotEmpty) return fb;
    return name.isNotEmpty ? name : 'User';
  }

  String resolveProfilePicture({String? fallback}) {
    final picture = profilePicture.trim();
    if (picture.isNotEmpty) return picture;
    return fallback?.trim() ?? '';
  }

  /// Fills gaps from [other] / [previewUrl] when API payloads are partial.
  Post mergedWith({
    Post? other,
    String? previewUrl,
    String? displayName,
    String? fallbackProfilePicture,
  }) {
    String pick(String primary, String? fallback) {
      final value = primary.trim();
      if (value.isNotEmpty && value != 'unknown') return value;
      final fb = fallback?.trim() ?? '';
      return fb;
    }

    int pickCount(int primary, int? fallback) {
      final secondary = fallback ?? 0;
      return primary > secondary ? primary : secondary;
    }

    final preview = previewUrl?.trim() ?? '';
    final mergedMedia = pick(media, other?.media);
    final resolvedMedia = mergedMedia.isNotEmpty
        ? mergedMedia
        : (preview.isNotEmpty ? preview : (other?.gridPreviewUrl ?? ''));

    final mergedThumb = thumbnailUrl.isNotEmpty
        ? thumbnailUrl
        : (other?.thumbnailUrl.isNotEmpty == true
              ? other!.thumbnailUrl
              : preview);

    final resolvedId = id.isNotEmpty ? id : (other?.id ?? '');

    return Post(
      id: resolvedId,
      caption: caption.isNotEmpty ? caption : (other?.caption ?? ''),
      media: resolvedMedia,
      thumbnailUrl: mergedThumb,
      userId: pick(userId, other?.userId),
      likesCount: pickCount(likesCount, other?.likesCount),
      commentsCount: pickCount(commentsCount, other?.commentsCount),
      sharesCount: pickCount(sharesCount, other?.sharesCount),
      isLiked: isLiked || (other?.isLiked ?? false),
      username: pick(username, other?.username ?? displayName),
      isSubscribed: isSubscribed || (other?.isSubscribed ?? false),
      profilePicture: pick(
        profilePicture,
        other?.profilePicture ?? fallbackProfilePicture,
      ),
      mediaType: isVideo || (other?.isVideo ?? false)
          ? 'video'
          : (other?.mediaType ?? mediaType),
      hasActiveStory: hasActiveStory || (other?.hasActiveStory ?? false),
      taggedUsers: taggedUsers.isNotEmpty
          ? taggedUsers
          : (other?.taggedUsers ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'media': media,
      'thumbnail_url': thumbnailUrl,
      'userId': userId,
      'mediaType': mediaType,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'is_liked': isLiked,
      'username': username,
      'is_subscribed': isSubscribed,
      'profile_picture': profilePicture,
      'has_active_story': hasActiveStory,
      'tagged_users': taggedUsers.map((e) => e.toJson()).toList(),
    };
  }
}

class TaggedUser {
  final String id;
  final String username;
  final String profilePicture;

  TaggedUser({
    required this.id,
    required this.username,
    required this.profilePicture,
  });

  factory TaggedUser.fromJson(Map<String, dynamic> json) {
    return TaggedUser(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? "",
      username: json['username']?.toString() ?? "",
      profilePicture: Post._normalizeUrl(
        json['profile_picture'] ??
            json['profilePicture'] ??
            json['avatar'] ??
            "",
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'profile_picture': profilePicture};
  }
}
