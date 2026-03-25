class CompleteProfileResponse {
  final bool success;
  final String message;

  CompleteProfileResponse({required this.success, required this.message});

  factory CompleteProfileResponse.fromJson(Map<String, dynamic> json) {
    return CompleteProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
