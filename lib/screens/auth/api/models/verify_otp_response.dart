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

  String? get resetToken => data?.accessToken; // ✅ FIXED
}

class OtpData {
  final String accessToken;
  final String refreshToken;

  OtpData({required this.accessToken, required this.refreshToken});

  factory OtpData.fromJson(Map<String, dynamic> json) {
    return OtpData(
      accessToken: json['access_token']?.toString() ?? "",
      refreshToken: json['refresh_token']?.toString() ?? "",
    );
  }
}
