class BlockedUserModel {
  final String userId;
  final String image;
  final String name;
  final String username;

  BlockedUserModel({
    required this.userId,
    required this.image,
    required this.name,
    required this.username,
  });

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      userId: json['user_id'] ?? '',
      image: json['profile_picture'] ?? '',
      name: json['full_name'] ?? '',
      username: json['username'] ?? '',
    );
  }
}
