import 'package:flutter/material.dart';

import 'package:gruve_app/features/story_preview/api/story_api/model/story_model.dart';
import 'package:gruve_app/features/story_preview/api/story_api/service/story_service.dart';

class StoryController extends ChangeNotifier {
  final StoryService _service = StoryService();

  bool isLoading = false;
  String message = "";
  bool isSuccess = false;
  
  // Stories data
  List<StoryItem> stories = [];
  int totalCount = 0;
  int currentPage = 1;
  bool hasNext = false;

  void reset() {
    message = "";
    isSuccess = false;
    stories = [];
    totalCount = 0;
    currentPage = 1;
    hasNext = false;
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
        debugPrint("✅ Story created successfully 🎉");
      } else {
        debugPrint("❌ Story failed: ${response.message}");
      }
    } catch (e) {
      debugPrint("💥 Controller error: $e");

      message = "Something went wrong 😓";
      isSuccess = false;
    } finally {
      isLoading = false;
      notifyListeners();

      debugPrint("🏁 ===== CONTROLLER END =====\n");
    }
  }

  Future<void> fetchStories({int page = 1, int limit = 5}) async {
    try {
      debugPrint("\n🎬 ===== FETCH STORIES CONTROLLER START =====");

      isLoading = true;
      isSuccess = false;
      message = "";
      notifyListeners();

      debugPrint("⏳ Loading started...");
      debugPrint("📄 Page: $page");
      debugPrint("📏 Limit: $limit");

      final response = await _service.fetchStories(
        page: page,
        limit: limit,
      );

      debugPrint("📥 API Response: ${response.message}");

      message = response.message;
      isSuccess = response.success;

      if (isSuccess) {
        debugPrint("✅ Stories fetched successfully 🎉");
        
        stories = response.data.stories;
        totalCount = response.data.count;
        currentPage = response.data.page;
        hasNext = response.data.hasNext;

        debugPrint("📚 Total stories: ${stories.length}");
        debugPrint("🔢 Total count: $totalCount");
        debugPrint("📄 Current page: $currentPage");
        debugPrint("➡️ Has next: $hasNext");
      } else {
        debugPrint("❌ Stories fetch failed: ${response.message}");
      }
    } catch (e) {
      debugPrint("💥 Controller error: $e");

      message = "Something went wrong 😓";
      isSuccess = false;
    } finally {
      isLoading = false;
      notifyListeners();

      debugPrint("🏁 ===== FETCH STORIES CONTROLLER END =====\n");
    }
  }
}
