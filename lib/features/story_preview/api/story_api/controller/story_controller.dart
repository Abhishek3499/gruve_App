import 'package:flutter/foundation.dart';

import 'package:gruve_app/features/story_preview/api/story_api/model/story_model.dart';
import 'package:gruve_app/features/story_preview/api/story_api/service/story_service.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class StoryController extends ChangeNotifier {
  StoryController({
    StoryService? service,
    HighlightStateManager? highlightStateManager,
  }) : _service = service ?? StoryService(),
       _highlightStateManager = highlightStateManager;

  final StoryService _service;
  HighlightStateManager? _highlightStateManager;

  bool isLoading = false;
  String message = "";
  bool isSuccess = false;

  // Stories data
  List<StoryItem> stories = [];
  int totalCount = 0;
  int currentPage = 1;
  bool hasNext = false;

  void attachHighlightStateManager(HighlightStateManager stateManager) {
    _highlightStateManager = stateManager;
  }

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
      AppLogger.d("\n🎬 ===== CONTROLLER START =====");
        AppLogger.d("⏳ Loading started...");
        AppLogger.d("📝 Caption: $caption");
        AppLogger.d("📁 Media Path: $mediaPath");
      

      isLoading = true;
      isSuccess = false;
      message = "";
      notifyListeners();

      final response = await _service.createStory(
        caption: caption,
        mediaPath: mediaPath,
      );

      AppLogger.d("📥 API Response: ${response.message}");
      

      message = response.message;
      isSuccess = response.success;

      if (kDebugMode) {
        if (isSuccess) {
          AppLogger.d("✅ Story created successfully 🎉");
        } else {
          AppLogger.d("❌ Story failed: ${response.message}");
        }
      }
    } catch (e) {
      AppLogger.d("💥 Controller error: $e");
      

      message = "Something went wrong 😓";
      isSuccess = false;
    } finally {
      isLoading = false;
      notifyListeners();

      AppLogger.d("🏁 ===== CONTROLLER END =====\n");
      
    }
  }

  Future<void> fetchStories({
    String? userId,
    int page = 1,
    int limit = 5,
  }) async {
    try {
      AppLogger.d("\n🎬 ===== FETCH STORIES CONTROLLER START =====");
        AppLogger.d("🧠 FetchStories:");
        AppLogger.d("➡️ userId: ${userId ?? 'me (own stories)'}");
        AppLogger.d("⏳ Loading started...");
        AppLogger.d("📄 Page: $page");
        AppLogger.d("📏 Limit: $limit");
      

      isLoading = true;
      isSuccess = false;
      message = "";
      notifyListeners();

      final response = await _service.fetchStories(
        userId: userId,
        page: page,
        limit: limit,
      );

      AppLogger.d("📥 API Response: ${response.message}");
      

      message = response.message;
      isSuccess = response.success;

      if (isSuccess) {
        AppLogger.d("✅ Stories fetched successfully 🎉");
        

        stories = response.data.stories;
        totalCount = response.data.count;
        currentPage = response.data.page;
        hasNext = response.data.hasNext;

        for (final story in stories) {
          if (story.isHighlighted == true) {
            await _highlightStateManager?.markStoryAsHighlighted(story.id);
          }
        }

        AppLogger.d("📚 Total stories: ${stories.length}");
          AppLogger.d("🔢 Total count: $totalCount");
          AppLogger.d("📄 Current page: $currentPage");
          AppLogger.d("➡️ Has next: $hasNext");
        
      } else {
        AppLogger.d("❌ Stories fetch failed: ${response.message}");
        
      }
    } catch (e) {
      AppLogger.d("💥 Controller error: $e");
      

      message = "Something went wrong 😓";
      isSuccess = false;
    } finally {
      isLoading = false;
      notifyListeners();

      AppLogger.d("🏁 ===== FETCH STORIES CONTROLLER END =====\n");
      
    }
  }
}
