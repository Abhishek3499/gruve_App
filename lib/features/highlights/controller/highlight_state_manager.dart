import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global state manager for tracking which stories are added to highlights
/// This is needed because the API doesn't provide stories data in highlights response
class HighlightStateManager extends GetxController {
  static HighlightStateManager get instance => Get.find();
  
  static const String _highlightedStoriesKey = 'highlighted_story_ids';

  // Reactive set of story IDs that are added to highlights
  final RxSet<String> _highlightedStoryIds = <String>{}.obs;

  /// Get all highlighted story IDs
  Set<String> get highlightedStoryIds => _highlightedStoryIds.toSet();

  /// Check if a specific story is highlighted
  bool isStoryHighlighted(String storyId) {
    return _highlightedStoryIds.contains(storyId);
  }

  /// Mark a story as highlighted
  Future<void> markStoryAsHighlighted(String storyId) async {
    if (storyId.isNotEmpty) {
      _highlightedStoryIds.add(storyId);
      await _saveToPreferences();
      debugPrint('[HighlightStateManager] Story $storyId marked as highlighted');
    }
  }

  /// Add highlighted story (alias for consistency)
  Future<void> addHighlightedStory(String storyId) async {
    await markStoryAsHighlighted(storyId);
  }

  /// Remove a story from highlighted list (if needed)
  Future<void> removeStoryFromHighlighted(String storyId) async {
    _highlightedStoryIds.remove(storyId);
    await _saveToPreferences();
    debugPrint('[HighlightStateManager] Story $storyId removed from highlighted list');
  }

  /// Clear all highlighted stories (for logout/reset)
  Future<void> clearAllHighlightedStories() async {
    _highlightedStoryIds.clear();
    await _saveToPreferences();
    debugPrint('[HighlightStateManager] All highlighted stories cleared');
  }

  /// Save highlighted story IDs to SharedPreferences
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storyIdsList = _highlightedStoryIds.toList();
      await prefs.setStringList(_highlightedStoriesKey, storyIdsList);
      debugPrint('[HighlightStateManager] Saved ${storyIdsList.length} highlighted stories to preferences');
    } catch (e) {
      debugPrint('[HighlightStateManager] Error saving to preferences: $e');
    }
  }

  /// Load highlighted story IDs from SharedPreferences
  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storyIdsList = prefs.getStringList(_highlightedStoriesKey) ?? [];
      _highlightedStoryIds.addAll(storyIdsList);
      debugPrint('[HighlightStateManager] Loaded ${storyIdsList.length} highlighted stories from preferences');
    } catch (e) {
      debugPrint('[HighlightStateManager] Error loading from preferences: $e');
    }
  }

  /// Initialize the singleton
  static void ensureRegistered() {
    if (!Get.isRegistered<HighlightStateManager>()) {
      Get.put(HighlightStateManager(), permanent: true);
      debugPrint('[HighlightStateManager] Registered singleton');
      // Load data from preferences after registration
      final instance = HighlightStateManager.instance;
      instance._loadFromPreferences();
    }
  }
}
