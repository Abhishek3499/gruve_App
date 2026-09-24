class ConnectionUser {
  final String userId;
  final String username;
  final String fullName;
  final String profilePicture;
  final String bio;
  final bool isSubscribed;

  const ConnectionUser({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.profilePicture,
    required this.bio,
    required this.isSubscribed,
  });

  factory ConnectionUser.fromJson(Map<String, dynamic> json) {
    return ConnectionUser(
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      isSubscribed: json['is_subscribed'] as bool? ?? false,
    );
  }
}

class ConnectionsPage {
  final String type;
  final int count;
  final int page;
  final int limit;
  final bool hasNext;
  final List<ConnectionUser> results;

  const ConnectionsPage({
    required this.type,
    required this.count,
    required this.page,
    required this.limit,
    required this.hasNext,
    required this.results,
  });

  factory ConnectionsPage.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as List<dynamic>? ?? [];
    return ConnectionsPage(
      type: json['type']?.toString() ?? '',
      count: json['count'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? resultsJson.length,
      hasNext: json['has_next'] as bool? ?? false,
      results: resultsJson
          .whereType<Map<String, dynamic>>()
          .map(ConnectionUser.fromJson)
          .toList(),
    );
  }
}
