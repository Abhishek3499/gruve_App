import 'package:gruve_app/core/utils/app_logger.dart';

/// Unified post model for feed functionality
/// Consolidates post-related data from various parts of the app
class PostModel {
  final String id;
  final String userId;
  final String username;
  final String? userAvatar;
  final String content;
  final String? mediaUrl;
  final MediaType mediaType;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLiked;
  final bool isSaved;
  final bool isOwnPost;
  final List<String> tags;
  final PostLocation? location;

  const PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.content,
    this.mediaUrl,
    this.mediaType = MediaType.image,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.createdAt,
    required this.updatedAt,
    this.isLiked = false,
    this.isSaved = false,
    this.isOwnPost = false,
    this.tags = const [],
    this.location,
  });

  /// Create from JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    final mediaUrl = json['media_url']?.toString() ?? json['mediaUrl']?.toString();
    var mediaType = _parseMediaType(json['media_type'] ?? json['mediaType']);
    if (mediaType == MediaType.image && _urlLooksLikeVideo(mediaUrl)) {
      mediaType = MediaType.video;
      AppLogger.d('🎥 video detected — inferred from URL in PostModel');
      
    }

    return PostModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? json['user']['username']?.toString() ?? '',
      userAvatar: json['user_avatar']?.toString() ?? json['user']['avatar']?.toString(),
      content: json['content']?.toString() ?? '',
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      likesCount: json['likes_count'] ?? json['likesCount'] ?? 0,
      commentsCount: json['comments_count'] ?? json['commentsCount'] ?? 0,
      sharesCount: json['shares_count'] ?? json['sharesCount'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? json['updatedAt'] ?? '') ?? DateTime.now(),
      isLiked: json['is_liked'] ?? json['isLiked'] ?? false,
      isSaved: json['is_saved'] ?? json['isSaved'] ?? false,
      isOwnPost: json['is_own_post'] ?? json['isOwnPost'] ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      location: json['location'] != null ? PostLocation.fromJson(json['location']) : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'user_avatar': userAvatar,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType.name,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_liked': isLiked,
      'is_saved': isSaved,
      'is_own_post': isOwnPost,
      'tags': tags,
      'location': location?.toJson(),
    };
  }

  /// Copy with updated values
  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? content,
    String? mediaUrl,
    MediaType? mediaType,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLiked,
    bool? isSaved,
    bool? isOwnPost,
    List<String>? tags,
    PostLocation? location,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isOwnPost: isOwnPost ?? this.isOwnPost,
      tags: tags ?? this.tags,
      location: location ?? this.location,
    );
  }

  static MediaType _parseMediaType(dynamic raw) {
    final s = raw?.toString().toLowerCase().trim() ?? '';
    switch (s) {
      case 'image':
      case 'photo':
      case '1':
      case '0':
        return MediaType.image;
      case 'video':
      case 'reel':
      case 'clip':
      case '2':
      case '3':
        return MediaType.video;
      case 'carousel':
        return MediaType.carousel;
      default:
        return MediaType.image;
    }
  }

  static bool _urlLooksLikeVideo(String? url) {
    if (url == null || url.isEmpty) return false;
    final path = url.toLowerCase().trim().split('?').first.split('#').first;
    const hints = ['.mp4', '.mov', '.m4v', '.webm', '.mkv', '.avi', '.m3u8', '.3gp'];
    for (final h in hints) {
      if (path.contains(h)) return true;
    }
    return false;
  }
}

/// Media type enum
enum MediaType {
  image,
  video,
  carousel,
}

/// Post location data
class PostLocation {
  final String name;
  final double latitude;
  final double longitude;

  const PostLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory PostLocation.fromJson(Map<String, dynamic> json) {
    return PostLocation(
      name: json['name']?.toString() ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
