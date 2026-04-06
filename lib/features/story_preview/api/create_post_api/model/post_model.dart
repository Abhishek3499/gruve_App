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

  Post({required this.id, required this.caption, required this.media});

  factory Post.fromJson(Map<String, dynamic> json) {
    print("📦 RAW POST JSON: $json");

    return Post(
      id: json['id'] ?? json['_id'] ?? "",
      caption: json['caption'] ?? "",
      media: json['media_url'] ?? "", // ✅ CORRECT
    );
  }
}
