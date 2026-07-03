import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/story_preview/api/create_post_api/model/post_model.dart';

class ExploreReelUser {
  final String id;
  final String username;
  final String profilePicture;

  const ExploreReelUser({
    required this.id,
    required this.username,
    this.profilePicture = '',
  });

  factory ExploreReelUser.fromJson(Map<String, dynamic> json) {
    return ExploreReelUser(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ??
          json['user_name']?.toString() ??
          json['name']?.toString() ??
          '',
      profilePicture: Post.normalizeMediaUrl(_pickString(json, const [
        'profile_picture',
        'profilePicture',
        'profile_image',
        'profileImage',
        'profile_pic',
        'profilePic',
        'avatar',
        'avatar_url',
        'avatarUrl',
        'photo',
        'picture',
        'image',
      ])),
    );
  }

  static String _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty && stringValue.toLowerCase() != 'null') {
        return stringValue;
      }
    }
    return '';
  }
}

class ExploreReel {
  final String id;
  final String thumbnail;
  final String mediaUrl;
  final int views;
  final int likes;
  final int shares;
  final DateTime? createdAt;
  final ExploreReelUser user;

  const ExploreReel({
    required this.id,
    required this.thumbnail,
    this.mediaUrl = '',
    required this.views,
    required this.likes,
    required this.shares,
    this.createdAt,
    required this.user,
  });

  bool get hasPlayableMedia {
    final media = _resolvedMediaUrl();
    return media.isNotEmpty;
  }

  /// Best network URL for grid thumbnails and playback.
  String get displayMediaUrl => _resolvedMediaUrl();

  String _resolvedMediaUrl() {
    final media = mediaUrl.trim();
    if (media.isNotEmpty &&
        (media.startsWith('http://') || media.startsWith('https://'))) {
      return media;
    }

    final thumb = thumbnail.trim();
    if (thumb.isNotEmpty &&
        Post.mediaUrlLooksLikeVideo(thumb) &&
        (thumb.startsWith('http://') || thumb.startsWith('https://'))) {
      return thumb;
    }
    return '';
  }

  String _resolvedThumbnailUrl() {
    final thumb = thumbnail.trim();
    if (thumb.isEmpty || Post.mediaUrlLooksLikeVideo(thumb)) return '';
    if (thumb.startsWith('http://') || thumb.startsWith('https://')) {
      return thumb;
    }
    return '';
  }

  /// Debug: print every URL field used for grid / playback.
  void logUrls({String prefix = ''}) {
    final preview = toPreviewPost();
    final tag = prefix.isEmpty ? 'ExploreReel' : 'ExploreReel/$prefix';

    AppLogger.d('────────── reel id=$id user=${user.username} ──────────', tag: tag);
    AppLogger.d('raw.thumbnail     = ${_orEmpty(thumbnail)}', tag: tag);
    AppLogger.d('raw.mediaUrl      = ${_orEmpty(mediaUrl)}', tag: tag);
    AppLogger.d('resolved.media    = ${_orEmpty(_resolvedMediaUrl())}', tag: tag);
    AppLogger.d('resolved.thumb    = ${_orEmpty(_resolvedThumbnailUrl())}', tag: tag);
    AppLogger.d('preview.media     = ${_orEmpty(preview.media)}', tag: tag);
    AppLogger.d('preview.thumbUrl  = ${_orEmpty(preview.thumbnailUrl)}', tag: tag);
    AppLogger.d('preview.gridUrl   = ${_orEmpty(preview.gridPreviewUrl)}', tag: tag);
    AppLogger.d('preview.mediaType = ${preview.mediaType}', tag: tag);
    AppLogger.d('user.profilePic   = ${_orEmpty(user.profilePicture)}', tag: tag);
    AppLogger.d('hasPlayableMedia  = $hasPlayableMedia', tag: tag);
  }

  static void logAllUrls(
    Iterable<ExploreReel> reels, {
    String prefix = '',
  }) {
    final list = reels.toList();
    if (list.isEmpty) {
      AppLogger.d('(no reels)', tag: 'ExploreReel');
      return;
    }

    AppLogger.d('══════ EXPLORE REEL URLS (${list.length}) ══════', tag: 'ExploreReel');
    for (var i = 0; i < list.length; i++) {
      list[i].logUrls(prefix: prefix.isEmpty ? '#$i' : '$prefix#$i');
    }
    AppLogger.d('══════ END EXPLORE REEL URLS ══════', tag: 'ExploreReel');
  }

  static String _orEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '(empty)' : trimmed;
  }

  factory ExploreReel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final cleanId = rawId.startsWith('pst_') ? rawId.substring(4) : rawId;

    Post? postHint;
    try {
      postHint = Post.fromJson(json);
    } catch (_) {
      postHint = null;
    }

    final userJson = json['user'] ?? json['creator'] ?? json['author'];
    final user = userJson is Map
        ? ExploreReelUser.fromJson(Map<String, dynamic>.from(userJson))
        : ExploreReelUser(
            id: json['user_id']?.toString() ?? json['creator_id']?.toString() ?? '',
            username: userJson is String
                ? userJson
                : (json['username']?.toString() ?? ''),
          );

    DateTime? createdAt;
    final createdRaw = json['created_at']?.toString();
    if (createdRaw != null && createdRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw);
    }

    var thumbnail = Post.normalizeMediaUrl(_extractThumbnail(json));
    var mediaUrl = Post.normalizeMediaUrl(_extractMediaUrl(json));

    if (mediaUrl.isEmpty && Post.mediaUrlLooksLikeVideo(thumbnail)) {
      mediaUrl = thumbnail;
    } else if (thumbnail.isEmpty) {
      thumbnail = postHint?.thumbnailUrl ?? '';
    }
    if (mediaUrl.isEmpty && postHint != null) {
      mediaUrl = postHint.media;
    }

    return ExploreReel(
      id: cleanId,
      thumbnail: thumbnail,
      mediaUrl: mediaUrl,
      views: _parseInt(json['views']),
      likes: _parseInt(json['likes']),
      shares: _parseInt(json['shares']),
      createdAt: createdAt,
      user: user,
    );
  }

  static String _extractThumbnail(Map<String, dynamic> json) {
    final direct = _readThumbnailValue(json);
    if (direct.isNotEmpty) return direct;

    for (final nestedKey in ['media', 'video', 'file', 'post']) {
      final nested = json[nestedKey];
      if (nested is! Map) continue;
      final fromNested = _readThumbnailValue(
        Map<String, dynamic>.from(nested),
      );
      if (fromNested.isNotEmpty) return fromNested;
    }
    return '';
  }

  static String _readThumbnailValue(Map<String, dynamic> json) {
    for (final key in [
      'thumbnail',
      'thumbnail_url',
      'thumbnailUrl',
      'poster',
      'poster_url',
      'posterUrl',
      'cover',
      'cover_url',
      'coverUrl',
      'preview',
      'preview_image',
      'previewImage',
      'preview_url',
      'previewUrl',
      'image',
      'image_url',
      'imageUrl',
      'video_thumbnail',
      'videoThumbnail',
      'thumb',
    ]) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is Map) {
        final nested = value['url'] ?? value['file'] ?? value['thumbnail'];
        if (nested != null && nested.toString().trim().isNotEmpty) {
          return nested.toString().trim();
        }
      }
    }
    return '';
  }

  static String _extractMediaUrl(Map<String, dynamic> json) {
    for (final key in [
      'media_url',
      'mediaUrl',
      'video_url',
      'videoUrl',
      'file',
      'url',
      'content_url',
      'contentUrl',
      'media',
      'video',
    ]) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        for (final nestedKey in [
          'url',
          'file',
          'media_url',
          'mediaUrl',
          'src',
          'video_url',
        ]) {
          final nested = map[nestedKey];
          if (nested != null && nested.toString().trim().isNotEmpty) {
            return nested.toString().trim();
          }
        }
      }
    }
    return '';
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Lightweight [Post] for grid thumbnails and playback when media is known.
  Post toPreviewPost() {
    final media = _resolvedMediaUrl();
    final imageThumb = _resolvedThumbnailUrl();
    final isVideoMedia =
        media.isNotEmpty && Post.mediaUrlLooksLikeVideo(media);

    return Post(
      id: id,
      caption: '',
      media: isVideoMedia ? media : (imageThumb.isNotEmpty ? imageThumb : media),
      thumbnailUrl: imageThumb,
      userId: user.id,
      likesCount: likes,
      commentsCount: 0,
      sharesCount: shares,
      isLiked: false,
      username: user.username,
      isSubscribed: false,
      profilePicture: user.profilePicture,
      mediaType: isVideoMedia ? 'video' : 'image',
    );
  }
}

class ExploreReelsPage {
  final int count;
  final String? next;
  final List<ExploreReel> results;

  const ExploreReelsPage({
    required this.count,
    this.next,
    required this.results,
  });

  bool get hasMore => next != null && next!.trim().isNotEmpty;

  int? get nextPage {
    final nextUrl = next?.trim();
    if (nextUrl == null || nextUrl.isEmpty) return null;

    final uri = Uri.tryParse(nextUrl);
    if (uri == null) return null;

    final pageParam = uri.queryParameters['page'];
    if (pageParam != null) return int.tryParse(pageParam);

    final segments = uri.pathSegments;
    for (var i = 0; i < segments.length - 1; i++) {
      if (segments[i] == 'page') {
        return int.tryParse(segments[i + 1]);
      }
    }
    return null;
  }

  factory ExploreReelsPage.fromJson(Map<String, dynamic> json) {
    final rawResults =
        json['results'] as List<dynamic>? ??
        json['reels'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        [];
    final reels = rawResults
        .whereType<Map>()
        .map((item) {
          try {
            return ExploreReel.fromJson(Map<String, dynamic>.from(item));
          } catch (_) {
            return null;
          }
        })
        .whereType<ExploreReel>()
        .where((reel) => reel.id.isNotEmpty)
        .toList();

    return ExploreReelsPage(
      count: ExploreReel._parseInt(json['count']),
      next: json['next']?.toString(),
      results: reels,
    );
  }
}
