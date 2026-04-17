import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreatePostResponse {
  final bool success;
  final String message;

  CreatePostResponse({required this.success, required this.message});

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) {
    print("Create response json: $json");

    return CreatePostResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
    );
  }
}

class Post {
  final String id;
  final String caption;
  final String media;
  final String userId;

  int likesCount;
  int commentsCount;
  bool isLiked;

  String username;
  bool isSubscribed;
  String profilePicture;

  Post({
    required this.id,
    required this.caption,
    required this.media,
    required this.userId,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.username,
    required this.isSubscribed,
    required this.profilePicture,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    print("Post json: $json");

    return Post(
      id: json['id']?.toString() ?? "",
      caption: json['caption']?.toString() ?? "",
      media: _normalizeUrl(
        json['media_url'] ?? json['media'] ?? json['file'] ?? "",
      ),
      userId:
          json['user']?['id']?.toString() ??
          json['user_id']?.toString() ??
          json['author_id']?.toString() ??
          "unknown",
      likesCount: json['likes_count'] ?? json['like_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? json['liked'] ?? false,
      username:
          json['user']?['username']?.toString() ??
          json['username']?.toString() ??
          "unknown",
      isSubscribed: json['user']?['is_subscribed'] ?? false,
      profilePicture: _normalizeUrl(
        json['user']?['profile_picture'] ?? json['profile_picture'] ?? "",
      ),
    );
  }

  static String _normalizeUrl(dynamic rawValue) {
    final value = rawValue?.toString().trim() ?? "";

    if (value.isEmpty || value.toLowerCase() == 'null') {
      return "";
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    final baseUrl = (dotenv.env['BASE_URL'] ?? "").trim();
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
