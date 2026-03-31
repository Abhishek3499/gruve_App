class VerifyOtpResponse {
  final bool success;
  final String message;
  final OtpData? data;

  VerifyOtpResponse({required this.success, required this.message, this.data});

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? "",
      data: json['data'] is Map<String, dynamic>
          ? OtpData.fromJson(json['data'])
          : null,
    );
  }

  String? get resetToken => data?.reset_token; // ✅ FIXED
}

class OtpData {
  final String accessToken;
  final String refreshToken;
  final String? reset_token; // ✅ ADDED

  OtpData({
    required this.accessToken,
    required this.refreshToken,
    this.reset_token,
  });

  factory OtpData.fromJson(Map<String, dynamic> json) {
    return OtpData(
      accessToken: json['access_token']?.toString() ?? "",
      refreshToken: json['refresh_token']?.toString() ?? "",
      reset_token: json['reset_token']?.toString(), // ✅ ADDED
    );
  }
}
