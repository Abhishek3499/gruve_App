class GoogleSignInResponse {
  final bool success;
  final String message;
  final GoogleSignInData? data;

  GoogleSignInResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory GoogleSignInResponse.fromJson(Map<String, dynamic> json) {
    return GoogleSignInResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? GoogleSignInData.fromJson(json['data'])
          : null,
    );
  }
}

class GoogleSignInData {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final bool isNewUser;
  final bool needsProfileSetup;

  GoogleSignInData({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.isNewUser,
    required this.needsProfileSetup,
  });

  factory GoogleSignInData.fromJson(Map<String, dynamic> json) {
    return GoogleSignInData(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      userId:
          json['user_id']?.toString() ?? json['user']?['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      isNewUser: json['is_new_user'] == true,
      needsProfileSetup: json['needs_profile_setup'] == true,
    );
  }
}
