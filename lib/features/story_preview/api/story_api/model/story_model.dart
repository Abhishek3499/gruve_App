import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/story_preview/models/story_media_model.dart';

class CreateStoryRequest {
  final String caption;
  final String file; // file path OR file url

  CreateStoryRequest({required this.caption, required this.file});
  Map<String, dynamic> toJson() {
    debugPrint("📤 Sending Create Story Request:");
    debugPrint("👉 Caption: $caption");
    debugPrint("👉 File: $file");

    final data = {"caption": caption, "file": file};

    debugPrint("👉 Final JSON: $data");

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

  StoryItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaMimeType,
    required this.mediaKind,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    debugPrint("📦 [StoryItem] Raw Data: $json");
    debugPrint("🆔 [StoryItem] ID: ${json['id']}");
    debugPrint("📺 [StoryItem] Media URL: ${json['media_url']}");
    debugPrint("📎 [StoryItem] MIME Type: ${json['media_mime_type']}");
    debugPrint("🎬 [StoryItem] Media Kind: ${json['media_kind']}");
    debugPrint("📝 [StoryItem] Caption: ${json['caption']}");
    debugPrint("📅 [StoryItem] Created At: ${json['created_at']}");
    debugPrint("⏰ [StoryItem] Expires At: ${json['expires_at']}");

    return StoryItem(
      id: json['id']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? '',
      mediaMimeType: json['media_mime_type']?.toString() ?? '',
      mediaKind: json['media_kind']?.toString() ?? '',
      caption: json['caption']?.toString(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().toIso8601String()),
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
    debugPrint("📥 [StoriesResponse] Raw Response: $json");
    debugPrint("🔢 [StoriesResponse] Code: ${json['code']}");
    debugPrint("✅ [StoriesResponse] Success: ${json['success']}");
    debugPrint("💬 [StoriesResponse] Message: ${json['message']}");
    debugPrint("📦 [StoriesResponse] Data: ${json['data']}");

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
    debugPrint("📊 [StoriesData] Raw Data: $json");
    debugPrint("🔢 [StoriesData] Count: ${json['count']}");
    debugPrint("📄 [StoriesData] Page: ${json['page']}");
    debugPrint("📏 [StoriesData] Limit: ${json['limit']}");
    debugPrint("➡️ [StoriesData] Has Next: ${json['has_next']}");

    final storiesList = json['stories'] as List?;
    debugPrint("📚 [StoriesData] Stories count in list: ${storiesList?.length ?? 0}");

    final stories = storiesList?.map((item) => StoryItem.fromJson(item)).toList() ?? [];

    debugPrint("✅ [StoriesData] Parsed ${stories.length} stories");

    return StoriesData(
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      hasNext: json['has_next'] ?? false,
      stories: stories,
    );
  }
}
