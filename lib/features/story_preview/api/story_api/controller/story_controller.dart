import 'package:flutter/foundation.dart';
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
      if (kDebugMode) {
        debugPrint("\n🎬 ===== CONTROLLER START =====");
        debugPrint("⏳ Loading started...");
        debugPrint("📝 Caption: $caption");
        debugPrint("📁 Media Path: $mediaPath");
      }

      isLoading = true;
      isSuccess = false;
      message = "";
      notifyListeners();

      final response = await _service.createStory(
        caption: caption,
        mediaPath: mediaPath,
      );

      if (kDebugMode) {
        debugPrint("📥 API Response: ${response.message}");
      }

      message = response.message;
      isSuccess = response.success;

      if (kDebugMode) {
        if (isSuccess) {
          debugPrint("✅ Story created successfully 🎉");
        } else {
          debugPrint("❌ Story failed: ${response.message}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("💥 Controller error: $e");
      }

      message = "Something went wrong 😓";
      isSuccess = false;
    } finally {
      isLoading = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint("🏁 ===== CONTROLLER END =====\n");
      }
    }
  }

  Future<void> fetchStories({String? userId, int page = 1, int limit = 5}) async {
    try {
      if (kDebugMode) {
        debugPrint("\n🎬 ===== FETCH STORIES CONTROLLER START =====");
        print("🧠 FetchStories:");
        print("➡️ userId: ${userId ?? 'me (own stories)'}");
        debugPrint("⏳ Loading started...");
        debugPrint("📄 Page: $page");
        debugPrint("📏 Limit: $limit");
      }

      isLoading = true;
      isSuccess = false;
      message = "";
      notifyListeners();

      final response = await _service.fetchStories(
        userId: userId,
        page: page,
        limit: limit,
      );

      if (kDebugMode) {
        debugPrint("📥 API Response: ${response.message}");
      }

      message = response.message;
      isSuccess = response.success;

      if (isSuccess) {
        if (kDebugMode) {
          debugPrint("✅ Stories fetched successfully 🎉");
        }

        stories = response.data.stories;
        totalCount = response.data.count;
        currentPage = response.data.page;
        hasNext = response.data.hasNext;

        if (kDebugMode) {
          debugPrint("📚 Total stories: ${stories.length}");
          debugPrint("🔢 Total count: $totalCount");
          debugPrint("📄 Current page: $currentPage");
          debugPrint("➡️ Has next: $hasNext");
        }
      } else {
        if (kDebugMode) {
          debugPrint("❌ Stories fetch failed: ${response.message}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("💥 Controller error: $e");
      }

      message = "Something went wrong 😓";
      isSuccess = false;
    } finally {
      isLoading = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint("🏁 ===== FETCH STORIES CONTROLLER END =====\n");
      }
    }
  }
}
