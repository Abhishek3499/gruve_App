class ResetPasswordResponse {
  final String message;
  final bool success;

  ResetPasswordResponse({required this.message, required this.success});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      message: json['message'] ?? "Password reset successful",
      success: json['success'] ?? true,
    );
  }
}
