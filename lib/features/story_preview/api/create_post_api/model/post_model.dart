class CreatePostResponse {
  final bool success;
  final String message;

  CreatePostResponse({required this.success, required this.message});

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) {
    return CreatePostResponse(
      success: json['success'],
      message: json['message'],
    );
  }
}

class Post {
  final String id;
  final String caption;
  final String media;

  Post({required this.id, required this.caption, required this.media});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? "",
      caption: json['caption'] ?? "",
      media: json['media'] ?? "",
    );
  }
}
