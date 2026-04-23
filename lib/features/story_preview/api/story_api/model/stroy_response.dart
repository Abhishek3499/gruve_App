class CreateStoryResponse {
  final bool success;
  final String message;

  CreateStoryResponse({required this.success, required this.message});

  factory CreateStoryResponse.fromJson(Map<String, dynamic> json) {
    print("📥 Raw Response: $json");

    return CreateStoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "Something went wrong",
    );
  }
}
