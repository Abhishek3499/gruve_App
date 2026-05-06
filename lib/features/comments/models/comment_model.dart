class CommentUser {
  final String id;
  final String username;
  final bool isSubscribed;
  final String? profilePicture;

  CommentUser({
    required this.id,
    required this.username,
    required this.isSubscribed,
    this.profilePicture,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['id'] ?? '',
      username: json['username'] ?? 'Unknown User',
      isSubscribed: json['is_subscribed'] ?? false,
      profilePicture: json['profile_picture'],
    );
  }
}

class Comment {
  final String id;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CommentUser user;

  Comment({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: (json['id'] ?? '').toString(),
      body: json['body'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      user: CommentUser.fromJson(json['user'] ?? {}),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays >= 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}

class CommentResponse {
  final String postId;
  final int count;
  final List<Comment> results;

  CommentResponse({
    required this.postId,
    required this.count,
    required this.results,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      postId: json['post_id'] ?? '',
      count: json['count'] ?? 0,
      results:
          (json['results'] as List?)
              ?.map((e) => Comment.fromJson(e))
              .toList() ??
          [],
    );
  }
}
