import 'package:gruve_app/core/utils/app_logger.dart';

class EditProfileResponse {
  final int code;
  final bool success;
  final String message;
  final EditProfileData data;
  final dynamic error;

  EditProfileResponse({
    required this.code,
    required this.success,
    required this.message,
    required this.data,
    this.error,
  }) {
    AppLogger.d("🏗️ [EditProfileResponse] Creating response object...");
    AppLogger.d(
      "📊 [EditProfileResponse] Data: code=$code, success=$success, message='$message', error=$error",
    );
  }

  factory EditProfileResponse.fromJson(Map<String, dynamic> json) {
    AppLogger.d("🔄 [EditProfileResponse] Parsing from JSON...");
    AppLogger.d("📄 [EditProfileResponse] Raw JSON: $json");

    final code = json['code'] ?? 200;
    final success = json['success'] ?? false;
    final message = json['message'] ?? '';
    final error = json['error'];

    AppLogger.d(
      "📝 [EditProfileResponse] Parsed fields: code=$code, success=$success, message='$message', error=$error",
    );

    AppLogger.d("🔧 [EditProfileResponse] Parsing nested data object...");
    final data = EditProfileData.fromJson(json['data'] ?? {});

    AppLogger.d("✅ [EditProfileResponse] JSON parsing completed successfully");

    return EditProfileResponse(
      code: code,
      success: success,
      message: message,
      data: data,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    AppLogger.d("🔄 [EditProfileResponse] Converting to JSON...");

    final json = {
      'code': code,
      'success': success,
      'message': message,
      'data': data.toJson(),
      'error': error,
    };

    AppLogger.d("✅ [EditProfileResponse] JSON conversion completed: $json");
    return json;
  }

  @override
  String toString() {
    return 'EditProfileResponse(code: $code, success: $success, message: $message, data: $data, error: $error)';
  }
}

class EditProfileData {
  final String? userId;
  final String username;
  final String? profilePicture;
  final String fullName;
  final String? phone;
  final String? email;
  final String gender;
  final String? bio;

  EditProfileData({
    this.userId,
    required this.username,
    this.profilePicture,
    required this.fullName,
    this.phone,
    this.email,
    required this.gender,
    this.bio,
  }) {
    AppLogger.d("🏗️ [EditProfileData] Creating data object...");
    AppLogger.d(
      "👤 [EditProfileData] User data: userId=$userId, username=$username, fullName=$fullName, email=$email",
    );
  }

  factory EditProfileData.fromJson(Map<String, dynamic> json) {
    AppLogger.d("🔄 [EditProfileData] Parsing from JSON...");
    AppLogger.d("📄 [EditProfileData] Raw JSON: $json");

    final userId = json['user_id'];
    final username = json['username'] ?? '';
    final profilePicture = json['profile_picture'];
    final fullName = json['full_name'] ?? '';
    final phone = json['phone'];
    final email = json['email'];
    final gender = json['gender'] ?? '';
    final bio = json['bio'];

    AppLogger.d("📝 [EditProfileData] Parsed fields:");
    AppLogger.d("  🆔 userId: $userId");
    AppLogger.d("  👤 username: '$username'");
    AppLogger.d("  🖼️ profile_picture: '$profilePicture'");
    AppLogger.d("  🏷️ fullName: '$fullName'");
    AppLogger.d("  📞 phone: '$phone'");
    AppLogger.d("  📧 email: '$email'");
    AppLogger.d("  ⚧️ gender: '$gender'");
    AppLogger.d("  📝 bio: '$bio'");

    AppLogger.d("✅ [EditProfileData] JSON parsing completed successfully");

    return EditProfileData(
      userId: userId,
      username: username,
      profilePicture: profilePicture,
      fullName: fullName,
      phone: phone,
      email: email,
      gender: gender,
      bio: bio,
    );
  }

  Map<String, dynamic> toJson() {
    AppLogger.d("🔄 [EditProfileData] Converting to JSON...");

    final json = {
      'user_id': userId,
      'username': username,
      'profile_picture': profilePicture,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'gender': gender,
      'bio': bio,
    };

    AppLogger.d("✅ [EditProfileData] JSON conversion completed: $json");
    return json;
  }

  @override
  String toString() {
    return 'EditProfileData(userId: $userId, username: $username, profile_picture: $profilePicture, fullName: $fullName, phone: $phone, email: $email, gender: $gender, bio: $bio)';
  }
}
