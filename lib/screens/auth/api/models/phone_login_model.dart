class PhoneloginResponse {
  final bool success;
  final String message;
  // final EmailSignInData? data;

  PhoneloginResponse({
    required this.success,
    required this.message,
    // this.data,
  });

  factory PhoneloginResponse.fromJson(Map<String, dynamic> json) {
    return PhoneloginResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? "",
      // data: json['data'] is Map<String, dynamic>
      //     ? EmailSignInData.fromJson(json['data'])
      //     : null,
    );
  }
}

class EmailSignInData {
  final String accessToken;
  final String refreshToken;

  EmailSignInData({required this.accessToken, required this.refreshToken});

  // // factory EmailSignInData.fromJson(Map<String, dynamic> json) {
  // //   return EmailSignInData(
  // //     accessToken: json['access_token']?.toString() ?? "",
  // //     refreshToken: json['refresh_token']?.toString() ?? "",
  // //   );
  // }
}
