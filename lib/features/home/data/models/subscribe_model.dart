class SubscribeModel {
  final String userId;
  final String username;
  final bool isSubscribed;
  final DateTime? subscribedAt;

  const SubscribeModel({
    required this.userId,
    required this.username,
    required this.isSubscribed,
    this.subscribedAt,
  });

  SubscribeModel copyWith({
    String? userId,
    String? username,
    bool? isSubscribed,
    DateTime? subscribedAt,
  }) {
    return SubscribeModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscribedAt: subscribedAt ?? this.subscribedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'isSubscribed': isSubscribed,
      'subscribedAt': subscribedAt?.toIso8601String(),
    };
  }

  factory SubscribeModel.fromJson(Map<String, dynamic> json) {
    return SubscribeModel(
      userId: json['userId'],
      username: json['username'],
      isSubscribed: json['isSubscribed'],
      subscribedAt: json['subscribedAt'] != null 
          ? DateTime.parse(json['subscribedAt']) 
          : null,
    );
  }
}
