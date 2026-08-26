import 'package:gruve_app/features/story_preview/domain/entities/story_media_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class CreateStoryRequest {
  final String caption;
  final String file; // file path OR file url

  CreateStoryRequest({required this.caption, required this.file});
  Map<String, dynamic> toJson() {
    AppLogger.d("📤 Sending Create Story Request:");
    AppLogger.d("👉 Caption: $caption");
    AppLogger.d("👉 File: $file");

    final data = {"caption": caption, "file": file};

    AppLogger.d("👉 Final JSON: $data");

    return data;
  }
}

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
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    AppLogger.d("📦 [StoryItem] Raw Data: $json");
    AppLogger.d("🆔 [StoryItem] ID: ${json['id']}");
    AppLogger.d("📺 [StoryItem] Media URL: ${json['media_url']}");
    AppLogger.d("📎 [StoryItem] MIME Type: ${json['media_mime_type']}");
    AppLogger.d("🎬 [StoryItem] Media Kind: ${json['media_kind']}");
    AppLogger.d("📝 [StoryItem] Caption: ${json['caption']}");
    AppLogger.d("📅 [StoryItem] Created At: ${json['created_at']}");
    AppLogger.d("⏰ [StoryItem] Expires At: ${json['expires_at']}");
    AppLogger.d("👤 [StoryItem] User ID: ${json['user_id']}");
    AppLogger.d("👤 [StoryItem] Username: ${json['username']}");
    AppLogger.d("🖼️ [StoryItem] Avatar URL: ${json['avatar_url']}");
    AppLogger.d("⭐ [StoryItem] Is Highlighted: ${json['is_highlighted']}");

    return StoryItem(
      id: json['id']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? '',
      mediaMimeType: json['media_mime_type']?.toString() ?? '',
      mediaKind: json['media_kind']?.toString() ?? '',
      caption: json['caption']?.toString(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().toIso8601String()),
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? json['profile_picture']?.toString(),
      isHighlighted: json['is_highlighted'] == true,
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
    AppLogger.d("📥 [StoriesResponse] Raw Response: $json");
    AppLogger.d("🔢 [StoriesResponse] Code: ${json['code']}");
    AppLogger.d("✅ [StoriesResponse] Success: ${json['success']}");
    AppLogger.d("💬 [StoriesResponse] Message: ${json['message']}");
    AppLogger.d("📦 [StoriesResponse] Data: ${json['data']}");

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
    AppLogger.d("📊 [StoriesData] Raw Data: $json");
    AppLogger.d("🔢 [StoriesData] Count: ${json['count']}");
    AppLogger.d("📄 [StoriesData] Page: ${json['page']}");
    AppLogger.d("📏 [StoriesData] Limit: ${json['limit']}");
    AppLogger.d("➡️ [StoriesData] Has Next: ${json['has_next']}");

    final storiesList = json['stories'] as List?;
    AppLogger.d("📚 [StoriesData] Stories count in list: ${storiesList?.length ?? 0}");

    final stories = storiesList?.map((item) => StoryItem.fromJson(item)).toList() ?? [];

    AppLogger.d("✅ [StoriesData] Parsed ${stories.length} stories");

    return StoriesData(
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      hasNext: json['has_next'] ?? false,
      stories: stories,
    );
  }
}
