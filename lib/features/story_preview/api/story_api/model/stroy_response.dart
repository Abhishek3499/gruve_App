import 'package:gruve_app/core/utils/app_logger.dart';

class CreateStoryResponse {
  final bool success;
  final String message;

  CreateStoryResponse({required this.success, required this.message});

  factory CreateStoryResponse.fromJson(Map<String, dynamic> json) {
    AppLogger.d("📥 [CreateStoryResponse] Raw Response: $json");
    AppLogger.d("✅ [CreateStoryResponse] Success: ${json['success']}");
    AppLogger.d("💬 [CreateStoryResponse] Message: ${json['message']}");

    return CreateStoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "Something went wrong",
    );
  }
}
