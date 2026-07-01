class HighlightModel {
  final String id;
  final String title;
  final int storiesCount;
  final String coverMediaUrl;
  final String createdAt;
  final List<HighlightStoryRef> stories;

  HighlightModel({
    required this.id,
    required this.title,
    required this.storiesCount,
    required this.coverMediaUrl,
    required this.createdAt,
    this.stories = const [],
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    final storiesList = _extractStoriesList(json);

    return HighlightModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      storiesCount: json['stories_count'] is int
          ? json['stories_count']
          : int.tryParse(json['stories_count']?.toString() ?? '0') ?? 0,
      coverMediaUrl: _extractCoverMediaUrl(json),
      createdAt: json['created_at']?.toString() ?? '',
      stories:
          storiesList
              ?.map((item) => HighlightStoryRef.fromJson(item))
              .where((story) => story.id.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  /// Best URL for highlight circle preview (image poster or video source).
  String? get coverPreviewUrl {
    if (coverMediaUrl.trim().isNotEmpty) return coverMediaUrl.trim();

    for (final story in stories) {
      final preview = story.previewUrl;
      if (preview != null && preview.isNotEmpty) return preview;
    }

    return null;
  }

  static String _extractCoverMediaUrl(Map<String, dynamic> json) {
    final direct =
        json['cover_media_url'] ??
        json['coverMediaUrl'] ??
        json['cover_url'] ??
        json['coverUrl'] ??
        json['cover'] ??
        json['thumbnail_url'] ??
        json['thumbnailUrl'] ??
        json['thumbnail'] ??
        json['poster'] ??
        json['image_url'] ??
        json['imageUrl'] ??
        json['image'];

    final value = direct?.toString().trim() ?? '';
    if (value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }

    final nestedCover = json['cover_media'];
    if (nestedCover is Map) {
      final map = Map<String, dynamic>.from(
        Map<Object?, Object?>.from(nestedCover),
      );
      final nested =
          map['url'] ??
          map['media_url'] ??
          map['thumbnail_url'] ??
          map['thumbnail'];
      final nestedValue = nested?.toString().trim() ?? '';
      if (nestedValue.isNotEmpty && nestedValue.toLowerCase() != 'null') {
        return nestedValue;
      }
    }

    return '';
  }

  static List? _extractStoriesList(Map<String, dynamic> json) {
    final rawStories = json['stories'] ?? json['story_ids'] ?? json['storyIds'];

    if (rawStories is List) return rawStories;

    if (rawStories is Map<String, dynamic>) {
      final nested =
          rawStories['stories'] ??
          rawStories['items'] ??
          rawStories['results'] ??
          rawStories['data'];
      if (nested is List) return nested;
    }

    return null;
  }

  bool containsStory(String storyId) {
    if (storyId.isEmpty) return false;
    return stories.any((story) => story.id.toString() == storyId.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'stories_count': storiesCount,
      'cover_media_url': coverMediaUrl,
      'created_at': createdAt,
      'stories': stories.map((story) => story.toJson()).toList(),
    };
  }
}

class HighlightStoryRef {
  final String id;
  final String mediaUrl;
  final String thumbnailUrl;

  const HighlightStoryRef({
    required this.id,
    this.mediaUrl = '',
    this.thumbnailUrl = '',
  });

  String? get previewUrl {
    if (thumbnailUrl.trim().isNotEmpty) return thumbnailUrl.trim();
    if (mediaUrl.trim().isNotEmpty) return mediaUrl.trim();
    return null;
  }

  factory HighlightStoryRef.fromJson(dynamic json) {
    if (json is String) {
      return HighlightStoryRef(id: json);
    }

    if (json is Map<String, dynamic>) {
      final nestedStory = json['story'];
      if (nestedStory is String || nestedStory is int) {
        return HighlightStoryRef(id: nestedStory.toString());
      }

      if (nestedStory is Map<String, dynamic>) {
        return HighlightStoryRef.fromJson(nestedStory);
      }

      return HighlightStoryRef(
        id:
            (json['story_id'] ??
                    json['storyId'] ??
                    json['story_uuid'] ??
                    json['storyUuid'] ??
                    json['story'] ??
                    json['id'] ??
                    json['uuid'] ??
                    '')
                .toString(),
        mediaUrl:
            (json['media_url'] ??
                    json['mediaUrl'] ??
                    json['cover_media_url'] ??
                    json['coverMediaUrl'] ??
                    json['file'] ??
                    '')
                .toString(),
        thumbnailUrl:
            (json['thumbnail_url'] ??
                    json['thumbnailUrl'] ??
                    json['thumbnail'] ??
                    json['poster'] ??
                    json['image'] ??
                    json['image_url'] ??
                    '')
                .toString(),
      );
    }

    return const HighlightStoryRef(id: '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'media_url': mediaUrl, 'thumbnail_url': thumbnailUrl};
  }
}

class HighlightsResponse {
  final int code;
  final bool success;
  final HighlightsData data;

  HighlightsResponse({
    required this.code,
    required this.success,
    required this.data,
  });

  factory HighlightsResponse.fromJson(Map<String, dynamic> json) {
    return HighlightsResponse(
      code: json['code'] ?? 200,
      success: json['success'] ?? false,
      data: HighlightsData.fromJson(json['data'] ?? {}),
    );
  }
}

class HighlightsData {
  final List<HighlightModel> highlights;

  HighlightsData({required this.highlights});

  factory HighlightsData.fromJson(Map<String, dynamic> json) {
    final highlightsList = json['highlights'] as List?;

    final highlights =
        highlightsList?.map((item) {
          return HighlightModel.fromJson(item);
        }).toList() ??
        [];

    return HighlightsData(highlights: highlights);
  }
}

class HighlightResponse {
  final int code;
  final bool success;
  final String message;
  final HighlightModel data;

  HighlightResponse({
    required this.code,
    required this.success,
    required this.message,
    required this.data,
  });

  factory HighlightResponse.fromJson(Map<String, dynamic> json) {
    return HighlightResponse(
      code: json['code'] ?? 200,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: HighlightModel.fromJson(json['data'] ?? json),
    );
  }
}
