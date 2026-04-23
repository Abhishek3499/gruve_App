import 'package:flutter/material.dart';

import 'package:gruve_app/features/story_preview/api/story_api/service/story_service.dart';

class StoryController extends ChangeNotifier {
  final StoryService _service = StoryService();

  bool isLoading = false;
  String message = "";
  bool isSuccess = false;

  // 🔥 Reset state (useful after success)
  void reset() {
    message = "";
    isSuccess = false;
    notifyListeners();
  }

  Future<void> createStory({
    required String caption,
    required String mediaPath,
  }) async {
    try {
      debugPrint("\n🎬 ===== CONTROLLER START =====");

      isLoading = true;
      isSuccess = false;
      message = "";
      notifyListeners();

      debugPrint("⏳ Loading started...");
      debugPrint("📝 Caption: $caption");
      debugPrint("📁 Media Path: $mediaPath");

      final response = await _service.createStory(
        caption: caption,
        mediaPath: mediaPath,
      );

      debugPrint("📥 API Response: ${response.message}");

      message = response.message;
      isSuccess = response.success;

      if (isSuccess) {
        debugPrint("✅ Story Created Successfully 🎉");
      } else {
        debugPrint("❌ Story Failed: ${response.message}");
      }
    } catch (e) {
      debugPrint("💥 Controller Error: $e");

      message = "Something went wrong 😓";
      isSuccess = false;
    } finally {
      isLoading = false;
      notifyListeners();

      debugPrint("🏁 ===== CONTROLLER END =====\n");
    }
  }
}
