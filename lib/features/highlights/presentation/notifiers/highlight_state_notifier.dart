import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Immutable state for [HighlightStateNotifier] tracking highlighted story IDs.
@immutable
class HighlightState {
  final Set<String> highlightedStoryIds;

  const HighlightState({this.highlightedStoryIds = const <String>{}});

  /// Check if a specific story is highlighted
  bool isStoryHighlighted(String storyId) {
    return highlightedStoryIds.contains(storyId);
  }

  HighlightState copyWith({Set<String>? highlightedStoryIds}) {
    return HighlightState(
      highlightedStoryIds: highlightedStoryIds ?? this.highlightedStoryIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighlightState &&
        setEquals(other.highlightedStoryIds, highlightedStoryIds);
  }

  @override
  int get hashCode => Object.hashAll(highlightedStoryIds);
}

class HighlightStateNotifier extends Notifier<HighlightState> {
  static const String _highlightedStoriesKey = 'highlighted_story_ids';

  @override
  HighlightState build() {
    unawaited(loadFromPreferences());
    return const HighlightState();
  }

  /// Get all highlighted story IDs
  Set<String> get highlightedStoryIds => state.highlightedStoryIds;

  /// Check if a specific story is highlighted
  bool isStoryHighlighted(String storyId) {
    return state.isStoryHighlighted(storyId);
  }

  /// Mark a story as highlighted
  Future<void> markStoryAsHighlighted(String storyId) async {
    if (storyId.isNotEmpty) {
      final updated = Set<String>.from(state.highlightedStoryIds)..add(storyId);
      state = state.copyWith(highlightedStoryIds: updated);
      await _saveToPreferences();
      AppLogger.d(
        '[HighlightStateNotifier] Story $storyId marked as highlighted',
      );
    }
  }

  /// Add highlighted story (alias for consistency)
  Future<void> addHighlightedStory(String storyId) async {
    await markStoryAsHighlighted(storyId);
  }

  /// Remove a story from highlighted list (if needed)
  Future<void> removeStoryFromHighlighted(String storyId) async {
    final updated = Set<String>.from(state.highlightedStoryIds)
      ..remove(storyId);
    state = state.copyWith(highlightedStoryIds: updated);
    await _saveToPreferences();
    AppLogger.d(
      '[HighlightStateNotifier] Story $storyId removed from highlighted list',
    );
  }

  /// Clear all highlighted stories (for logout/reset)
  Future<void> clearAllHighlightedStories() async {
    state = state.copyWith(highlightedStoryIds: <String>{});
    await _saveToPreferences();
    AppLogger.d('[HighlightStateNotifier] All highlighted stories cleared');
  }

  /// Save highlighted story IDs to SharedPreferences
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storyIdsList = state.highlightedStoryIds.toList();
      await prefs.setStringList(_highlightedStoriesKey, storyIdsList);
      AppLogger.d(
        '[HighlightStateNotifier] Saved ${storyIdsList.length} highlighted stories to preferences',
      );
    } catch (e) {
      AppLogger.d('[HighlightStateNotifier] Error saving to preferences: $e');
    }
  }

  /// Load highlighted story IDs from SharedPreferences
  Future<void> loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storyIdsList = prefs.getStringList(_highlightedStoriesKey) ?? [];
      state = state.copyWith(highlightedStoryIds: storyIdsList.toSet());
      AppLogger.d(
        '[HighlightStateNotifier] Loaded ${storyIdsList.length} highlighted stories from preferences',
      );
    } catch (e) {
      AppLogger.d(
        '[HighlightStateNotifier] Error loading from preferences: $e',
      );
    }
  }
}

/// App-scoped provider for [HighlightStateNotifier]
final highlightStateNotifierProvider =
    NotifierProvider<HighlightStateNotifier, HighlightState>(
      HighlightStateNotifier.new,
    );
