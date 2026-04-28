class HighlightModel {
  final String id;
  final String title;
  final int storiesCount;
  final String coverMediaUrl;
  final String createdAt;

  HighlightModel({
    required this.id,
    required this.title,
    required this.storiesCount,
    required this.coverMediaUrl,
    required this.createdAt,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      storiesCount: json['stories_count'] is int 
          ? json['stories_count'] 
          : int.tryParse(json['stories_count']?.toString() ?? '0') ?? 0,
      coverMediaUrl: json['cover_media_url']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'stories_count': storiesCount,
      'cover_media_url': coverMediaUrl,
      'created_at': createdAt,
    };
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

  HighlightsData({
    required this.highlights,
  });

  factory HighlightsData.fromJson(Map<String, dynamic> json) {
    final highlightsList = json['highlights'] as List?;

    final highlights = highlightsList?.map((item) {
      return HighlightModel.fromJson(item);
    }).toList() ?? [];

    return HighlightsData(
      highlights: highlights,
    );
  }
}
