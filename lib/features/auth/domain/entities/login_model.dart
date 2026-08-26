class EmailSignInResponse {
  final bool success;
  final String message;
  final EmailSignInData? data;

  EmailSignInResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory EmailSignInResponse.fromJson(Map<String, dynamic> json) {
    return EmailSignInResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? "",
      data: json['data'] is Map<String, dynamic>
          ? EmailSignInData.fromJson(json['data'])
          : null,
    );
  }
}

class EmailSignInData {
  final String accessToken;
  final String refreshToken;
  final String userId;

  EmailSignInData({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  factory EmailSignInData.fromJson(Map<String, dynamic> json) {
    return EmailSignInData(
      accessToken: json['access_token']?.toString() ?? "",
      refreshToken: json['refresh_token']?.toString() ?? "",
      userId: json['user_id']?.toString() ?? json['user']?['id']?.toString() ?? "",
    );
  }
}
