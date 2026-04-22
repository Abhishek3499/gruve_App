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
  });

  factory EditProfileResponse.fromJson(Map<String, dynamic> json) {
    return EditProfileResponse(
      code: json['code'] ?? 200,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: EditProfileData.fromJson(json['data'] ?? {}),
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'success': success,
      'message': message,
      'data': data.toJson(),
      'error': error,
    };
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
  });

  factory EditProfileData.fromJson(Map<String, dynamic> json) {
    return EditProfileData(
      userId: json['user_id'],
      username: json['username'] ?? '',
      profilePicture: json['profile_picture'],
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      gender: json['gender'] ?? '',
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'profile_picture': profilePicture,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'gender': gender,
      'bio': bio,
    };
  }
}
