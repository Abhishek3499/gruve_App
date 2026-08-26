import 'package:gruve_app/core/config/environment_config.dart';

class PostDraft {
  final String id;
  final String? caption;
  final String? mediaUrl;
  final String? locationName;
  final bool audienceEveryone;
  final bool audienceCloseFriends;
  final bool scheduleReel;
  final bool uploadHighQuality;
  final bool hideLikeCount;
  final bool hideShareCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PostDraft({
    required this.id,
    this.caption,
    this.mediaUrl,
    this.locationName,
    this.audienceEveryone = true,
    this.audienceCloseFriends = false,
    this.scheduleReel = false,
    this.uploadHighQuality = false,
    this.hideLikeCount = false,
    this.hideShareCount = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isVideo =>
      mediaUrl != null &&
      (mediaUrl!.toLowerCase().endsWith('.mp4') ||
          mediaUrl!.toLowerCase().endsWith('.mov') ||
          mediaUrl!.toLowerCase().endsWith('.avi') ||
          mediaUrl!.toLowerCase().endsWith('.mkv') ||
          mediaUrl!.toLowerCase().endsWith('.webm'));

  factory PostDraft.fromJson(Map<String, dynamic> json) {
    return PostDraft(
      id: json['id']?.toString() ?? "",
      caption: json['caption']?.toString(),
      mediaUrl: _normalizeUrl(json['file'] ?? json['media_url'] ?? json['media']),
      locationName: json['location_name']?.toString(),
      audienceEveryone: json['audience_everyone'] == true || json['audience_everyone'] == 'true' || json['audience_everyone'] == null,
      audienceCloseFriends: json['audience_close_friends'] == true || json['audience_close_friends'] == 'true',
      scheduleReel: json['schedule_reel'] == true || json['schedule_reel'] == 'true',
      uploadHighQuality: json['upload_high_quality'] == true || json['upload_high_quality'] == 'true',
      hideLikeCount: json['hide_like_count'] == true || json['hide_like_count'] == 'true',
      hideShareCount: json['hide_share_count'] == true || json['hide_share_count'] == 'true',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  static String? _normalizeUrl(dynamic rawValue) {
    if (rawValue == null) return null;
    final value = rawValue.toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return null;
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
}

class PaginatedDraftsResponse {
  final int count;
  final int page;
  final int limit;
  final bool hasNext;
  final List<PostDraft> results;

  PaginatedDraftsResponse({
    required this.count,
    required this.page,
    required this.limit,
    required this.hasNext,
    required this.results,
  });

  factory PaginatedDraftsResponse.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List<dynamic>? ?? [];
    return PaginatedDraftsResponse(
      count: json['count'] is int ? json['count'] as int : (int.tryParse(json['count']?.toString() ?? '') ?? 0),
      page: json['page'] is int ? json['page'] as int : (int.tryParse(json['page']?.toString() ?? '') ?? 1),
      limit: json['limit'] is int ? json['limit'] as int : (int.tryParse(json['limit']?.toString() ?? '') ?? 20),
      hasNext: json['has_next'] == true || json['has_next'] == 'true',
      results: resultsList.map((e) => PostDraft.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
