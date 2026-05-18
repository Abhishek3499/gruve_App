import 'package:flutter/material.dart';

class EditProfileRequest {
  final String fullname;
  final String username;
  final String? bio;
  final String? profilePicture;

  EditProfileRequest({
    required this.fullname,
    required this.username,
    this.bio,
    this.profilePicture,
  }) {
    debugPrint("🏗️ [EditProfileRequest] Creating request object...");
    debugPrint(
      "📝 [EditProfileRequest] Data: fullname='$fullname', username='$username', bio='$bio', profile_picture='$profilePicture'",
    );
  }

  Map<String, dynamic> toJson() {
    debugPrint("🔄 [EditProfileRequest] Converting to JSON...");

    final data = <String, dynamic>{'fullname': fullname, 'username': username};

    if (bio?.isNotEmpty == true) {
      data['bio'] = bio;
      debugPrint("📝 [EditProfileRequest] Added bio: '$bio'");
    } else {
      debugPrint("📝 [EditProfileRequest] Bio omitted (null or empty)");
    }

    if (profilePicture?.isNotEmpty == true) {
      data['profile_picture'] = profilePicture;
      debugPrint(
        "🖼️ [EditProfileRequest] Added profile_picture: '$profilePicture'",
      );
    } else {
      debugPrint(
        "🖼️ [EditProfileRequest] ProfilePicture omitted (null or empty)",
      );
    }

    debugPrint("✅ [EditProfileRequest] JSON conversion completed: $data");
    return data;
  }

  @override
  String toString() {
    return 'EditProfileRequest(fullname: $fullname, username: $username, bio: $bio, profile_picture: $profilePicture)';
  }
}
