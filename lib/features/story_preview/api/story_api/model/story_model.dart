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
    debugPrint("📦 Parsing StoryItem:");
    debugPrint("🆔 ID: ${json['id']}");
    debugPrint("📺 Media URL: ${json['media_url']}");
    debugPrint("📎 MIME Type: ${json['media_mime_type']}");
    debugPrint("🎬 Media Kind: ${json['media_kind']}");
    debugPrint("📝 Caption: ${json['caption']}");

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
    debugPrint("📥 Parsing StoriesResponse:");
    debugPrint("🔢 Code: ${json['code']}");
    debugPrint("✅ Success: ${json['success']}");
    debugPrint("💬 Message: ${json['message']}");

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
    debugPrint("📊 Parsing StoriesData:");
    debugPrint("🔢 Count: ${json['count']}");
    debugPrint("📄 Page: ${json['page']}");
    debugPrint("📏 Limit: ${json['limit']}");
    debugPrint("➡️ Has Next: ${json['has_next']}");

    final storiesList = json['stories'] as List?;
    debugPrint("📚 Stories count in list: ${storiesList?.length ?? 0}");

    final stories = storiesList?.map((item) => StoryItem.fromJson(item)).toList() ?? [];

    return StoriesData(
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      hasNext: json['has_next'] ?? false,
      stories: stories,
    );
  }
}
