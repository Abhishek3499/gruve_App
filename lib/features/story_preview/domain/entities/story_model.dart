import 'package:gruve_app/features/story_preview/domain/entities/story_media_model.dart';

/// Individual story item from the API
class StoryItem {
  final String id;
  final String mediaUrl;
  final String mediaMimeType;
  final String mediaKind;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  // User context fields
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool isHighlighted;
  final String visibility;

  StoryItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaMimeType,
    required this.mediaKind,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.isHighlighted = false,
    this.visibility = 'public',
  });

  /// Instagram-style close friends story — true when [visibility] is 'close_friends'.
  bool get isCloseFriends => visibility == 'close_friends';

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? '',
      mediaMimeType: json['media_mime_type']?.toString() ?? '',
      mediaKind: json['media_kind']?.toString() ?? '',
      caption: json['caption']?.toString(),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        json['expires_at'] ?? DateTime.now().toIso8601String(),
      ),
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl:
          json['avatar_url']?.toString() ?? json['profile_picture']?.toString(),
      isHighlighted: json['is_highlighted'] == true,
      visibility: json['visibility']?.toString() ?? 'public',
    );
  }

  /// Convert to StoryMediaModel for compatibility with existing code
  StoryMediaModel toStoryMediaModel() {
    return StoryMediaModel(
      mediaPath: mediaUrl,
      mediaType: mediaKind == 'video' ? MediaType.video : MediaType.image,
      createdAt: createdAt,
    );
  }
}

/// Response model for stories/me API
class StoriesResponse {
  final int code;
  final bool success;
  final String message;
  final StoriesData data;

  StoriesResponse({
    required this.code,
    required this.success,
    required this.message,
    required this.data,
  });

  factory StoriesResponse.fromJson(Map<String, dynamic> json) {
    return StoriesResponse(
      code: json['code'] ?? 200,
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: StoriesData.fromJson(json['data'] ?? {}),
    );
  }
}

/// Data section of stories response
class StoriesData {
  final int count;
  final int page;
  final int limit;
  final bool hasNext;
  final List<StoryItem> stories;

  StoriesData({
    required this.count,
    required this.page,
    required this.limit,
    required this.hasNext,
    required this.stories,
  });

  factory StoriesData.fromJson(Map<String, dynamic> json) {
    final storiesList = json['stories'] as List?;

    final stories =
        storiesList?.map((item) => StoryItem.fromJson(item)).toList() ?? [];

    return StoriesData(
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      hasNext: json['has_next'] ?? false,
      stories: stories,
    );
  }
}
