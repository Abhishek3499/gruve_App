class NotificationListResponse {
  final int code;
  final bool success;
  final String message;
  final NotificationPageData? data;

  NotificationListResponse({
    required this.code,
    required this.success,
    required this.message,
    this.data,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      code: json['code'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? NotificationPageData.fromJson(json['data']) : null,
    );
  }
}

class NotificationPageData {
  final int count;
  final int unreadCount;
  final int page;
  final int limit;
  final bool hasNext;
  final List<AppNotification> results;

  NotificationPageData({
    required this.count,
    required this.unreadCount,
    required this.page,
    required this.limit,
    required this.hasNext,
    required this.results,
  });

  factory NotificationPageData.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List?;
    List<AppNotification> resultsList = list != null
        ? list.map((i) => AppNotification.fromJson(i)).toList()
        : [];

    return NotificationPageData(
      count: json['count'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      hasNext: json['has_next'] ?? false,
      results: resultsList,
    );
  }
}

class AppNotification {
  final int id;
  final String type;
  final String? postId;
  final String? commentId;
  final String? commentPreview;
  final bool isRead;
  final String createdAt;
  final NotificationActor? actor;

  AppNotification({
    required this.id,
    required this.type,
    this.postId,
    this.commentId,
    this.commentPreview,
    required this.isRead,
    required this.createdAt,
    this.actor,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      postId: json['post_id']?.toString(),
      commentId: json['comment_id']?.toString(),
      commentPreview: json['comment_preview']?.toString(),
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
      actor: json['actor'] != null ? NotificationActor.fromJson(json['actor']) : null,
    );
  }

  AppNotification copyWith({
    int? id,
    String? type,
    String? postId,
    String? commentId,
    String? commentPreview,
    bool? isRead,
    String? createdAt,
    NotificationActor? actor,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      commentPreview: commentPreview ?? this.commentPreview,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actor: actor ?? this.actor,
    );
  }
}

class NotificationActor {
  final String id;
  final String username;
  final String fullName;
  final String? profilePicture;

  NotificationActor({
    required this.id,
    required this.username,
    required this.fullName,
    this.profilePicture,
  });

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      profilePicture: json['profile_picture']?.toString(),
    );
  }
}
