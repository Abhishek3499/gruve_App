class EditProfileRequest {
  final String fullName;
  final String username;
  final String? bio;
  final String? profilePicture;

  EditProfileRequest({
    required this.fullName,
    required this.username,
    this.bio,
    this.profilePicture,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'full_name': fullName,
      'username': username,
    };

    if (bio?.isNotEmpty == true) {
      data['bio'] = bio;
    }

    if (profilePicture?.isNotEmpty == true) {
      data['profile_picture'] = profilePicture;
    }

    return data;
  }
}
