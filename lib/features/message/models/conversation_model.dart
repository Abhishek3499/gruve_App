import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/foundation.dart';
import '../../../core/parsing/safe_parsing_helpers.dart';

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
    debugPrint('👤 [OtherUser] 🔍 Starting user parsing');
    final safeJson = SafeParsingHelpers.validateAndCleanMap(json, context: '👤 OtherUser.fromJson');
    final flat = _flattenUserJson(safeJson);
    debugPrint('👤 [OtherUser] 🗺️ Flattened keys: ${flat.keys.toList()}');
    
    return OtherUser(
      id: SafeParsingHelpers.safeString(flat, const ['id', 'user_id', '_id', 'pk'], fallback: ''),
      name: SafeParsingHelpers.safeString(
        flat,
        const ['name', 'full_name', 'fullname', 'username', 'display_name'],
        fallback: 'Unknown',
      ),
      avatar: SafeParsingHelpers.safeNullableString(
        flat,
        const [
          'avatar',
          'profile_picture',
          'profileImage',
          'profile_image',
          'photo',
          'image',
        ],
      ),
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

Map<String, dynamic> _flattenUserJson(Map<String, dynamic> json) {
  final base = Map<String, dynamic>.from(json);

  void overlay(dynamic node) {
    if (node is! Map) return;
    final map = Map<String, dynamic>.from(node);
    for (final entry in map.entries) {
      final value = entry.value;
      final existing = base[entry.key];
      final existingEmpty = existing == null ||
          (existing is String && existing.trim().isEmpty);
      if (existingEmpty && value != null) {
        base[entry.key] = value;
      }
    }
  }

  overlay(json['user']);
  overlay(json['profile']);
  overlay(json['data']);
  if (json['data'] is Map) {
    final data = Map<String, dynamic>.from(json['data'] as Map);
    overlay(data['user']);
    overlay(data['profile']);
  }

  return base;
}

String _pickString(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  return _pickNullableString(map, keys) ?? fallback;
}

String? _pickNullableString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final stringValue = value.toString().trim();
    if (stringValue.isNotEmpty && stringValue.toLowerCase() != 'null') {
      return stringValue;
    }
  }
  return null;
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
    debugPrint('📨 [LastMessage] 🔍 Starting message parsing');
    final safeJson = SafeParsingHelpers.validateAndCleanMap(json, context: '📨 LastMessage.fromJson');
    debugPrint('📨 [LastMessage] 🗺️ Message keys: ${safeJson.keys.toList()}');
    
    return LastMessage(
      content: SafeParsingHelpers.safeString(safeJson, const ['content', 'text', 'message'], fallback: ''),
      createdAt: _parseDateTime(
        safeJson['created_at'] ?? safeJson['createdAt'] ?? safeJson['timestamp'],
      ),
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
        return DateTime.parse(dateTime).toLocal();
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
  final String? participant_1_id;
  final String? participant_2_id;

  const ConversationModel({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
    this.participant_1_id,
    this.participant_2_id,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    debugPrint('💬 [ConversationModel] 🔍 Starting conversation parsing');
    final safeJson = SafeParsingHelpers.validateAndCleanMap(json, context: '💬 ConversationModel.fromJson');
    debugPrint('💬 [ConversationModel] 🗺️ Conversation keys: ${safeJson.keys.toList()}');
    
    // Safely extract nested objects
    final otherUserData = SafeParsingHelpers.safeMapParse(
      safeJson['other_user'] ??
          safeJson['otherUser'] ??
          safeJson['user'] ??
          safeJson['participant'] ??
          {},
      context: '💬 ConversationModel.otherUser'
    );
    
    final lastMessageData = SafeParsingHelpers.safeMapParse(
      safeJson['last_message'] ?? safeJson['lastMessage'] ?? {},
      context: '💬 ConversationModel.lastMessage'
    );
    
    debugPrint('💬 [ConversationModel] 👤 Other user keys: ${otherUserData.keys.toList()}');
    debugPrint('💬 [ConversationModel] 📨 Last message keys: ${lastMessageData.keys.toList()}');
    
    return ConversationModel(
      id: SafeParsingHelpers.safeString(safeJson, const ['id', '_id', 'conversation_id'], fallback: ''),
      otherUser: OtherUser.fromJson(otherUserData),
      lastMessage: LastMessage.fromJson(lastMessageData),
      updatedAt: _parseDateTime(
        safeJson['updated_at'] ?? safeJson['updatedAt'] ?? safeJson['last_message_at'],
      ),
      unreadCount: SafeParsingHelpers.safeInt(safeJson, const ['unread_count', 'unreadCount'], fallback: 0),
      participant_1_id: SafeParsingHelpers.safeNullableString(safeJson, const ['participant_1_id', 'participant1Id']),
      participant_2_id: SafeParsingHelpers.safeNullableString(safeJson, const ['participant_2_id', 'participant2Id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'other_user': otherUser.toJson(),
      'last_message': lastMessage.toJson(),
      'updated_at': updatedAt.toIso8601String(),
      'unread_count': unreadCount,
      'participant_1_id': participant_1_id,
      'participant_2_id': participant_2_id,
    };
  }

  /// Parse DateTime from ISO string with fallback
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime).toLocal();
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
    String? participant_1_id,
    String? participant_2_id,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      participant_1_id: participant_1_id ?? this.participant_1_id,
      participant_2_id: participant_2_id ?? this.participant_2_id,
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
        other.unreadCount == unreadCount &&
        other.participant_1_id == participant_1_id &&
        other.participant_2_id == participant_2_id;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        otherUser.hashCode ^
        lastMessage.hashCode ^
        updatedAt.hashCode ^
        unreadCount.hashCode ^
        participant_1_id.hashCode ^
        participant_2_id.hashCode;
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, otherUser: $otherUser, lastMessage: $lastMessage, updatedAt: $updatedAt, unreadCount: $unreadCount, participant_1_id: $participant_1_id, participant_2_id: $participant_2_id)';
  }
}
