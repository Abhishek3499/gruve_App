class SignupResponse {
  final int code;
  final bool success;
  final String message;
  final UserData? data;
  final dynamic error;

  SignupResponse({
    required this.code,
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      code: json["code"] ?? 0,
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: json["data"] != null ? UserData.fromJson(json["data"]) : null,
      error: json["error"],
    );
  }
}

class UserData {
  final String id;
  final String fullName;
  final String email;

  UserData({required this.id, required this.fullName, required this.email});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json["id"] ?? "",
      fullName: json["full_name"] ?? "", // 🔥 IMPORTANT
      email: json["email"] ?? "",
    );
  }
}
