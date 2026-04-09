class CreatePostResponse {
  final bool success;
  final String message;

  CreatePostResponse({required this.success, required this.message});

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) {
    print("🧾 CREATE RESPONSE JSON: $json");

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
  int commentsCount; // ✅ NEW
  bool isLiked;

  String username;
  bool isSubscribed; // ✅ NEW
  String profilePicture; // ✅ NEW

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
    print("🧾 POST JSON: $json");

    return Post(
      id: json['id'] ?? "",
      caption: json['caption'] ?? "",
      media: json['media_url'] ?? "",
      userId: json['user']?['id'] ?? json['user_id'] ?? "unknown",

      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0, // ✅

      isLiked: json['is_liked'] ?? false,

      username: json['user']?['username'] ?? "unknown",
      isSubscribed: json['user']?['is_subscribed'] ?? false, // ✅
      profilePicture: json['user']?['profile_picture'] ?? "", // ✅
    );
  }
}
