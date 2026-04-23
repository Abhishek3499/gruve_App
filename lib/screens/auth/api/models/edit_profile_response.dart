import 'package:flutter/material.dart';

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
    debugPrint("🏗️ [EditProfileResponse] Creating response object...");
    debugPrint(
      "📊 [EditProfileResponse] Data: code=$code, success=$success, message='$message', error=$error",
    );
  }

  factory EditProfileResponse.fromJson(Map<String, dynamic> json) {
    debugPrint("🔄 [EditProfileResponse] Parsing from JSON...");
    debugPrint("📄 [EditProfileResponse] Raw JSON: $json");

    final code = json['code'] ?? 200;
    final success = json['success'] ?? false;
    final message = json['message'] ?? '';
    final error = json['error'];

    debugPrint(
      "📝 [EditProfileResponse] Parsed fields: code=$code, success=$success, message='$message', error=$error",
    );

    debugPrint("🔧 [EditProfileResponse] Parsing nested data object...");
    final data = EditProfileData.fromJson(json['data'] ?? {});

    debugPrint("✅ [EditProfileResponse] JSON parsing completed successfully");

    return EditProfileResponse(
      code: code,
      success: success,
      message: message,
      data: data,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    debugPrint("🔄 [EditProfileResponse] Converting to JSON...");

    final json = {
      'code': code,
      'success': success,
      'message': message,
      'data': data.toJson(),
      'error': error,
    };

    debugPrint("✅ [EditProfileResponse] JSON conversion completed: $json");
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
  final String? profile_picture;
  final String fullName;
  final String? phone;
  final String? email;
  final String gender;
  final String? bio;

  EditProfileData({
    this.userId,
    required this.username,
    this.profile_picture,
    required this.fullName,
    this.phone,
    this.email,
    required this.gender,
    this.bio,
  }) {
    debugPrint("🏗️ [EditProfileData] Creating data object...");
    debugPrint(
      "👤 [EditProfileData] User data: userId=$userId, username=$username, fullName=$fullName, email=$email",
    );
  }

  factory EditProfileData.fromJson(Map<String, dynamic> json) {
    debugPrint("🔄 [EditProfileData] Parsing from JSON...");
    debugPrint("📄 [EditProfileData] Raw JSON: $json");

    final userId = json['user_id'];
    final username = json['username'] ?? '';
    final profile_picture = json['profile_picture'];
    final fullName = json['full_name'] ?? '';
    final phone = json['phone'];
    final email = json['email'];
    final gender = json['gender'] ?? '';
    final bio = json['bio'];

    debugPrint("📝 [EditProfileData] Parsed fields:");
    debugPrint("  🆔 userId: $userId");
    debugPrint("  👤 username: '$username'");
    debugPrint("  🖼️ profile_picture: '$profile_picture'");
    debugPrint("  🏷️ fullName: '$fullName'");
    debugPrint("  📞 phone: '$phone'");
    debugPrint("  📧 email: '$email'");
    debugPrint("  ⚧️ gender: '$gender'");
    debugPrint("  📝 bio: '$bio'");

    debugPrint("✅ [EditProfileData] JSON parsing completed successfully");

    return EditProfileData(
      userId: userId,
      username: username,
      profile_picture: profile_picture,
      fullName: fullName,
      phone: phone,
      email: email,
      gender: gender,
      bio: bio,
    );
  }

  Map<String, dynamic> toJson() {
    debugPrint("🔄 [EditProfileData] Converting to JSON...");

    final json = {
      'user_id': userId,
      'username': username,
      'profile_picture': profile_picture,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'gender': gender,
      'bio': bio,
    };

    debugPrint("✅ [EditProfileData] JSON conversion completed: $json");
    return json;
  }

  @override
  String toString() {
    return 'EditProfileData(userId: $userId, username: $username, profile_picture: $profile_picture, fullName: $fullName, phone: $phone, email: $email, gender: $gender, bio: $bio)';
  }
}
