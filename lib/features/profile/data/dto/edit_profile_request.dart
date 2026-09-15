import 'package:gruve_app/core/utils/app_logger.dart';

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
    AppLogger.d("🏗️ [EditProfileRequest] Creating request object...");
    AppLogger.d(
      "📝 [EditProfileRequest] Data: fullname='$fullname', username='$username', bio='$bio', profile_picture='$profilePicture'",
    );
  }

  Map<String, dynamic> toJson() {
    AppLogger.d("🔄 [EditProfileRequest] Converting to JSON...");

    final data = <String, dynamic>{'fullname': fullname, 'username': username};

    if (bio?.isNotEmpty == true) {
      data['bio'] = bio;
      AppLogger.d("📝 [EditProfileRequest] Added bio: '$bio'");
    } else {
      AppLogger.d("📝 [EditProfileRequest] Bio omitted (null or empty)");
    }

    if (profilePicture?.isNotEmpty == true) {
      data['profile_picture'] = profilePicture;
      AppLogger.d(
        "🖼️ [EditProfileRequest] Added profile_picture: '$profilePicture'",
      );
    } else {
      AppLogger.d(
        "🖼️ [EditProfileRequest] ProfilePicture omitted (null or empty)",
      );
    }

    AppLogger.d("✅ [EditProfileRequest] JSON conversion completed: $data");
    return data;
  }

  @override
  String toString() {
    return 'EditProfileRequest(fullname: $fullname, username: $username, bio: $bio, profile_picture: $profilePicture)';
  }
}
