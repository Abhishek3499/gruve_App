import 'package:timeago/timeago.dart' as timeago;

/// Model representing the other user in a conversation
class OtherUser {
  final String id;
  final String name;
  final String? avatar;

  const OtherUser({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory OtherUser.fromJson(Map<String, dynamic> json) {
    return OtherUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }

  OtherUser copyWith({
    String? id,
    String? name,
    String? avatar,
  }) {
    return OtherUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OtherUser &&
        other.id == id &&
        other.name == name &&
        other.avatar == avatar;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ avatar.hashCode;

  @override
  String toString() => 'OtherUser(id: $id, name: $name, avatar: $avatar)';
}

/// Model representing the last message in a conversation
class LastMessage {
  final String content;
  final DateTime createdAt;

  const LastMessage({
    required this.content,
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Parse DateTime from ISO string with fallback
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  /// Get formatted time ago string (e.g., "5 min ago", "1 hour ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    // Handle very recent messages
    if (difference.inSeconds < 60) {
      return 'just now';
    }
    
    // Use timeago for proper formatting
    return timeago.format(createdAt, allowFromNow: true);
  }

  LastMessage copyWith({
    String? content,
    DateTime? createdAt,
  }) {
    return LastMessage(
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LastMessage &&
        other.content == content &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => content.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'LastMessage(content: $content, createdAt: $createdAt)';
}

/// Model representing a conversation
class ConversationModel {
  final String id;
  final OtherUser otherUser;
  final LastMessage lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      otherUser: OtherUser.fromJson(json['other_user'] as Map<String, dynamic>? ?? {}),
      lastMessage: LastMessage.fromJson(json['last_message'] as Map<String, dynamic>? ?? {}),
      updatedAt: _parseDateTime(json['updated_at']),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'other_user': otherUser.toJson(),
      'last_message': lastMessage.toJson(),
      'updated_at': updatedAt.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  /// Parse DateTime from ISO string with fallback
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  /// Get formatted time ago string for the last message
  String get lastMessageTimeAgo => lastMessage.timeAgo;

  /// Get the other user's name
  String get otherUserName => otherUser.name;

  /// Get the other user's avatar URL
  String? get otherUserAvatar => otherUser.avatar;

  /// Get the last message content
  String get lastMessageContent => lastMessage.content;

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  ConversationModel copyWith({
    String? id,
    OtherUser? otherUser,
    LastMessage? lastMessage,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationModel &&
        other.id == id &&
        other.otherUser == otherUser &&
        other.lastMessage == lastMessage &&
        other.updatedAt == updatedAt &&
        other.unreadCount == unreadCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        otherUser.hashCode ^
        lastMessage.hashCode ^
        updatedAt.hashCode ^
        unreadCount.hashCode;
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, otherUser: $otherUser, lastMessage: $lastMessage, updatedAt: $updatedAt, unreadCount: $unreadCount)';
  }
}
