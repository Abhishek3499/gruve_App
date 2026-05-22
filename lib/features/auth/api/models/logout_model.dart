class LogoutResponse {
  final bool success;
  final String message;

  LogoutResponse({required this.success, required this.message});

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? "",
    );
  }
}

class LogoutRequest {
  final String refreshToken;

  LogoutRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {"refresh_token": refreshToken};
  }
}
