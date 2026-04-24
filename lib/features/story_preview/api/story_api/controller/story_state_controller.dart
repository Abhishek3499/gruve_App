import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Story data model for better organization
class StoryData {
  final String mediaPath;
  final DateTime createdAt;

  StoryData({required this.mediaPath, required this.createdAt});
}

/// Optimized controller for managing story state across the app
class StoryStateController extends ChangeNotifier {
  static final StoryStateController _instance =
      StoryStateController._internal();
  factory StoryStateController() => _instance;
  StoryStateController._internal() {
    _loadStoriesFromStorage();
  }

  List<StoryData> _userStories = [];
  String? _username;
  String? _avatarUrl;

  // Storage keys
  static const String _storiesKey = 'user_stories';
  static const String _usernameKey = 'story_username';
  static const String _avatarKey = 'story_avatar';

  bool get hasUserStory => _userStories.isNotEmpty;
  List<String> get currentUserStoryMediaPaths =>
      _userStories.map((s) => s.mediaPath).toList();
  DateTime? get storyCreatedAt =>
      _userStories.isNotEmpty ? _userStories.first.createdAt : null;
  String? get username => _username;
  String? get avatarUrl => _avatarUrl;
  List<DateTime> get storyTimestamps =>
      _userStories.map((s) => s.createdAt).toList();

  /// Update story status with validation
  Future<void> updateStory({String? mediaPath, DateTime? createdAt}) async {
    debugPrint("\n📝 ===== UPDATE STORY CALLED =====");
    debugPrint("📁 Media Path: $mediaPath");
    debugPrint("📅 Created At: $createdAt");

    if (mediaPath == null || mediaPath.isEmpty) {
      debugPrint("⚠️ Empty media path, clearing stories");
      clearStory();
      return;
    }

    // Check if story already exists to avoid duplicates
    final existingIndex = _userStories.indexWhere(
      (story) => story.mediaPath == mediaPath,
    );
    debugPrint("🔍 Story exists at index: $existingIndex");

    if (existingIndex == -1) {
      // Add new story if it doesn't exist
      debugPrint("➕ Adding new story to list");
      _userStories.add(
        StoryData(mediaPath: mediaPath, createdAt: createdAt ?? DateTime.now()),
      );
    } else {
      // Update existing story timestamp
      debugPrint("🔄 Updating existing story timestamp");
      _userStories[existingIndex] = StoryData(
        mediaPath: mediaPath,
        createdAt: createdAt ?? DateTime.now(),
      );
    }

    debugPrint("📊 Total stories now: ${_userStories.length}");
    notifyListeners();
    await _saveStoriesToStorage();
    debugPrint("✅ Story updated successfully");
    debugPrint("🏁 ===== UPDATE STORY END =====\n");
  }

  /// Add a new story to the list
  Future<void> addStory(String mediaPath, {DateTime? createdAt}) async {
    debugPrint("\n➕ ===== ADD STORY CALLED =====");
    debugPrint("📁 Media Path: $mediaPath");
    debugPrint("📅 Created At: $createdAt");

    if (mediaPath.isNotEmpty) {
      _userStories.add(
        StoryData(mediaPath: mediaPath, createdAt: createdAt ?? DateTime.now()),
      );
      debugPrint("📊 Stories before sort: ${_userStories.length}");
      _sortStoriesByTime();
      debugPrint("📊 Stories after sort: ${_userStories.length}");
      notifyListeners();
      await _saveStoriesToStorage();
      debugPrint("✅ Story added successfully");
    } else {
      debugPrint("⚠️ Empty media path, story not added");
    }
    debugPrint("🏁 ===== ADD STORY END =====\n");
  }

  /// Set user info from profile
  Future<void> setUserInfo({String? username, String? avatarUrl}) async {
    debugPrint("\n👤 ===== SET USER INFO CALLED =====");
    debugPrint("🆔 Username: $username");
    debugPrint("🖼️ Avatar: $avatarUrl");

    _username = username;
    _avatarUrl = avatarUrl;
    notifyListeners();
    await _saveStoriesToStorage();

    debugPrint("✅ User info updated");
    debugPrint("🏁 ===== SET USER INFO END =====\n");
  }

  /// Set stories from API response (replaces entire list)
  Future<void> setStoriesFromAPI(
    List<String> mediaPaths, {
    List<DateTime>? createdAts,
    String? username,
    String? avatarUrl,
  }) async {
    debugPrint("\n🌐 ===== SET STORIES FROM API CALLED =====");
    debugPrint("📱 Media Paths: ${mediaPaths.length} items");
    debugPrint("⏰ Timestamps: ${createdAts?.length ?? 0} items");
    debugPrint("👤 Username: $username");
    debugPrint("🖼️ Avatar: $avatarUrl");

    _userStories.clear();
    debugPrint("🗑️ Cleared existing stories");

    // Update user info if provided
    if (username != null) _username = username;
    if (avatarUrl != null) _avatarUrl = avatarUrl;

    for (int i = 0; i < mediaPaths.length; i++) {
      final mediaPath = mediaPaths[i];
      if (mediaPath.isNotEmpty) {
        _userStories.add(
          StoryData(
            mediaPath: mediaPath,
            createdAt: createdAts != null && i < createdAts.length
                ? createdAts[i]
                : DateTime.now(),
          ),
        );
        debugPrint("📝 Added story $i: $mediaPath");
      }
    }

    _sortStoriesByTime();
    debugPrint("📊 Total stories set: ${_userStories.length}");
    notifyListeners();
    await _saveStoriesToStorage();
    debugPrint("✅ Stories set from API successfully");
    debugPrint("🏁 ===== SET STORIES FROM API END =====\n");
  }

  /// Sort stories by creation time (newest first)
  void _sortStoriesByTime() {
    debugPrint("🔄 Sorting stories by time...");
    _userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    debugPrint("✅ Stories sorted (newest first)");
  }

  /// Mark story as shared (simplified method)
  void markStoryAsShared(String mediaPath) {
    debugPrint("\n📤 ===== MARK STORY AS SHARED CALLED =====");
    debugPrint("📁 Media Path: $mediaPath");

    if (mediaPath.isNotEmpty) {
      debugPrint("✅ Marking story as shared");
      updateStory(mediaPath: mediaPath);
    } else {
      debugPrint("⚠️ Empty media path, cannot mark as shared");
    }
    debugPrint("🏁 ===== MARK STORY AS SHARED END =====\n");
  }

  /// Clear story state
  Future<void> clearStory() async {
    debugPrint("\n🗑️ ===== CLEAR STORY CALLED =====");
    debugPrint("📊 Stories before clear: ${_userStories.length}");

    _userStories = [];
    notifyListeners();
    await _saveStoriesToStorage();

    debugPrint("✅ All stories cleared");
    debugPrint("🏁 ===== CLEAR STORY END =====\n");
  }

  /// Reset controller state
  void reset() {
    debugPrint("\n🔄 ===== RESET CONTROLLER CALLED =====");
    clearStory();
    debugPrint("✅ Controller reset complete");
    debugPrint("🏁 ===== RESET CONTROLLER END =====\n");
  }

  // 💾 PERSISTENT STORAGE METHODS

  /// Load stories from SharedPreferences
  Future<void> _loadStoriesFromStorage() async {
    try {
      debugPrint("\n💾 ===== LOADING STORIES FROM STORAGE =====");

      final prefs = await SharedPreferences.getInstance();

      // Load stories
      final storiesJson = prefs.getString(_storiesKey);
      if (storiesJson != null) {
        final List<dynamic> storiesList = jsonDecode(storiesJson);
        _userStories = storiesList.map((storyJson) {
          final story = storyJson as Map<String, dynamic>;
          return StoryData(
            mediaPath: story['mediaPath'],
            createdAt: DateTime.parse(story['createdAt']),
          );
        }).toList();
        debugPrint("📚 Loaded ${_userStories.length} stories from storage");
      } else {
        debugPrint("📭 No stories found in storage");
      }

      // Load user info
      _username = prefs.getString(_usernameKey);
      _avatarUrl = prefs.getString(_avatarKey);

      debugPrint("👤 Loaded user: $_username");
      debugPrint("🖼️ Loaded avatar: $_avatarUrl");
      debugPrint("✅ Stories loaded from storage successfully");
      debugPrint("🏁 ===== LOADING STORIES FROM STORAGE END =====\n");

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading stories from storage: $e");
    }
  }

  /// Save stories to SharedPreferences
  Future<void> _saveStoriesToStorage() async {
    try {
      debugPrint("\n💾 ===== SAVING STORIES TO STORAGE =====");

      final prefs = await SharedPreferences.getInstance();

      // Save stories
      final storiesJson = jsonEncode(
        _userStories
            .map(
              (story) => {
                'mediaPath': story.mediaPath,
                'createdAt': story.createdAt.toIso8601String(),
              },
            )
            .toList(),
      );

      await prefs.setString(_storiesKey, storiesJson);
      debugPrint("💾 Saved ${_userStories.length} stories to storage");

      // Save user info
      if (_username != null) {
        await prefs.setString(_usernameKey, _username!);
        debugPrint("👤 Saved username: $_username");
      }

      if (_avatarUrl != null) {
        await prefs.setString(_avatarKey, _avatarUrl!);
        debugPrint("🖼️ Saved avatar: $_avatarUrl");
      }

      debugPrint("✅ Stories saved to storage successfully");
      debugPrint("🏁 ===== SAVING STORIES TO STORAGE END =====\n");
    } catch (e) {
      debugPrint("❌ Error saving stories to storage: $e");
    }
  }
}
