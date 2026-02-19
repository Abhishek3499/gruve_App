/// Profile model representing user profile information
class ProfileModel {
  /// User's unique username/handle
  final String username;
  
  /// User's bio/description
  final String bio;
  
  /// User's email address
  final String email;
  
  /// Path to profile image (asset or network)
  final String profileImagePath;

  const ProfileModel({
    required this.username,
    required this.bio,
    required this.email,
    required this.profileImagePath,
  });

  /// Creates a copy of ProfileModel with updated values
  ProfileModel copyWith({
    String? username,
    String? bio,
    String? email,
    String? profileImagePath,
  }) {
    return ProfileModel(
      username: username ?? this.username,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  /// Converts ProfileModel to JSON for storage/API
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'bio': bio,
      'email': email,
      'profileImagePath': profileImagePath,
    };
  }

  /// Creates ProfileModel from JSON
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      email: json['email'] ?? '',
      profileImagePath: json['profileImagePath'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileModel &&
        other.username == username &&
        other.bio == bio &&
        other.email == email &&
        other.profileImagePath == profileImagePath;
  }

  @override
  int get hashCode {
    return username.hashCode ^
        bio.hashCode ^
        email.hashCode ^
        profileImagePath.hashCode;
  }

  @override
  String toString() {
    return 'ProfileModel(username: $username, bio: $bio, email: $email, profileImagePath: $profileImagePath)';
  }
}
