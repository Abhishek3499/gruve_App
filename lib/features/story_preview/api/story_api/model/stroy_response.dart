import 'package:flutter/foundation.dart';

class CreateStoryResponse {
  final bool success;
  final String message;

  CreateStoryResponse({required this.success, required this.message});

  factory CreateStoryResponse.fromJson(Map<String, dynamic> json) {
    debugPrint("📥 [CreateStoryResponse] Raw Response: $json");
    debugPrint("✅ [CreateStoryResponse] Success: ${json['success']}");
    debugPrint("💬 [CreateStoryResponse] Message: ${json['message']}");

    return CreateStoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "Something went wrong",
    );
  }
}
