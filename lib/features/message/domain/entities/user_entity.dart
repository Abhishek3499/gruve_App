class UserEntity {
  final String userId;
  final String username;
  final String fullName;
  final String? profilePicture;

  const UserEntity({
    required this.userId,
    required this.username,
    required this.fullName,
    this.profilePicture,
  });
}
