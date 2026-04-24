import 'package:flutter/material.dart';

import 'package:gruve_app/features/story_preview/api/story_api/service/story_service.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';

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

  // 👤 SET USER INFO METHOD
  Future<void> setUserInfo({String? username, String? avatarUrl}) async {
    final storyStateController = StoryStateController();
    await storyStateController.setUserInfo(username: username, avatarUrl: avatarUrl);
  }

  // 📥 FETCH STORIES METHOD
  Future<void> fetchStories() async {
    try {
      debugPrint("\n🎬 ===== FETCH CONTROLLER START =====");

      isLoading = true;
      notifyListeners();

      final storyPaths = await _service.fetchStories();
      
      // Update the state controller with fetched stories
      final storyStateController = StoryStateController();
      await storyStateController.setStoriesFromAPI(storyPaths);

      debugPrint("📚 Fetched ${storyPaths.length} stories");
      debugPrint("🏁 ===== FETCH CONTROLLER END =====\n");
    } catch (e) {
      debugPrint("💥 Fetch Controller Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
