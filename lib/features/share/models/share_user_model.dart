class ShareUserModel {
  final String id;
  final String username;
  final String avatar;
  final bool isOnline;

  ShareUserModel({
    required this.id,
    required this.username,
    required this.avatar,
    this.isOnline = false,
  });

  // Factory constructor for creating from JSON
  factory ShareUserModel.fromJson(Map<String, dynamic> json) {
    return ShareUserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  // Method for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'isOnline': isOnline,
    };
  }

  // Copy with method for immutability
  ShareUserModel copyWith({
    String? id,
    String? username,
    String? avatar,
    bool? isOnline,
  }) {
    return ShareUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareUserModel &&
        other.id == id &&
        other.username == username &&
        other.avatar == avatar &&
        other.isOnline == isOnline;
  }

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ avatar.hashCode ^ isOnline.hashCode;

  @override
  String toString() => 'ShareUserModel(id: $id, username: $username, avatar: $avatar, isOnline: $isOnline)';
}
