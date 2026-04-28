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
    _currentUserId = null; // Will be set when needed
    _isLoadingFromStorage = false; // Don't auto-load on init
  }

  List<StoryData> _userStories = [];
  String? _username;
  String? _avatarUrl;
  bool _isLoadingFromStorage = false;
  String? _currentUserId; // Track current user for cache isolation

  // Cache expiry duration (5 minutes)
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Storage key helpers (per-user)
  String _getStoriesKey(String? userId) => 'stories_${userId ?? 'me'}';
  String _getUsernameKey(String? userId) => 'story_username_${userId ?? 'me'}';
  String _getAvatarKey(String? userId) => 'story_avatar_${userId ?? 'me'}';
  String _getTimestampKey(String? userId) => 'story_timestamp_${userId ?? 'me'}';

  bool get hasUserStory => _userStories.isNotEmpty;
  bool get isLoadingFromStorage => _isLoadingFromStorage;
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
    await _saveStoriesToStorage(_currentUserId);
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
      await _saveStoriesToStorage(_currentUserId);
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
    await _saveStoriesToStorage(_currentUserId);

    debugPrint("✅ User info updated");
    debugPrint("🏁 ===== SET USER INFO END =====\n");
  }

  /// Set stories from API response (replaces entire list)
  Future<void> setStoriesFromAPI(
    List<String> mediaPaths, {
    List<DateTime>? createdAts,
    String? username,
    String? avatarUrl,
    String? userId,
  }) async {
    debugPrint("\n🌐 ===== SET STORIES FROM API CALLED =====");
    debugPrint("📱 Media Paths: ${mediaPaths.length} items");
    debugPrint("⏰ Timestamps: ${createdAts?.length ?? 0} items");
    debugPrint("👤 Username: $username");
    debugPrint("🖼️ Avatar: $avatarUrl");
    debugPrint("🆔 UserId: $userId");

    // Clear previous user's data if switching users
    if (userId != null && _currentUserId != null && userId != _currentUserId) {
      print("🔄 USER SWITCH:");
      print("➡️ Old: $_currentUserId → New: $userId");
      await _clearUserCache(_currentUserId);
    }

    _currentUserId = userId;
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
    await _saveStoriesToStorage(userId);
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
    await _saveStoriesToStorage(_currentUserId);

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

  /// Clear all story data including user info (for logout)
  Future<void> clearAllData() async {
    debugPrint("\n🗑️ ===== CLEAR ALL DATA CALLED =====");
    debugPrint("📊 Stories before clear: ${_userStories.length}");

    _userStories = [];
    _username = null;
    _avatarUrl = null;
    _currentUserId = null;
    notifyListeners();
    await _clearAllCache();

    debugPrint("✅ All story data cleared (stories, username, avatar)");
    debugPrint("🏁 ===== CLEAR ALL DATA END =====\n");
  }

  /// Clear cache for a specific user
  Future<void> _clearUserCache(String? userId) async {
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getStoriesKey(userId));
    await prefs.remove(_getUsernameKey(userId));
    await prefs.remove(_getAvatarKey(userId));
    await prefs.remove(_getTimestampKey(userId));

    debugPrint("🗑️ Cleared cache for user: $userId");
  }

  /// Clear all story cache (for logout)
  Future<void> _clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith('stories_') ||
          key.startsWith('story_username_') ||
          key.startsWith('story_avatar_') ||
          key.startsWith('story_timestamp_')) {
        await prefs.remove(key);
      }
    }

    debugPrint("🗑️ Cleared all story cache");
  }

  /// Check if cache is expired
  Future<bool> _isCacheExpired(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(_getTimestampKey(userId));

    if (timestampStr == null) return true;

    final timestamp = DateTime.tryParse(timestampStr);
    if (timestamp == null) return true;

    final isExpired = DateTime.now().difference(timestamp) > _cacheExpiry;
    if (isExpired) {
      debugPrint("⏰ Cache expired for user: ${userId ?? 'me'}");
    }

    return isExpired;
  }

  // 💾 PERSISTENT STORAGE METHODS

  /// Load stories from SharedPreferences
  Future<void> _loadStoriesFromStorage(String? userId) async {
    try {
      debugPrint("\n💾 ===== LOADING STORIES FROM STORAGE =====");

      print("� LOAD CACHE:");
      print("➡️ Key: stories_${userId ?? 'me'}");

      final prefs = await SharedPreferences.getInstance();

      // Check if cache is expired
      if (await _isCacheExpired(userId)) {
        debugPrint("⏰ Cache expired, skipping load");
        await _clearUserCache(userId);
        _isLoadingFromStorage = false;
        notifyListeners();
        return;
      }

      // Load stories
      final storiesJson = prefs.getString(_getStoriesKey(userId));
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
      _username = prefs.getString(_getUsernameKey(userId));
      _avatarUrl = prefs.getString(_getAvatarKey(userId));

      debugPrint("👤 Loaded user: $_username");
      debugPrint("🖼️ Loaded avatar: $_avatarUrl");
      debugPrint("✅ Stories loaded from storage successfully");
      debugPrint("🏁 ===== LOADING STORIES FROM STORAGE END =====\n");

      _isLoadingFromStorage = false;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading stories from storage: $e");
      _isLoadingFromStorage = false;
      notifyListeners();
    }
  }

  /// Save stories to SharedPreferences
  Future<void> _saveStoriesToStorage(String? userId) async {
    try {
      debugPrint("\n💾 ===== SAVING STORIES TO STORAGE =====");

      print("💾 SAVE CACHE:");
      print("➡️ Key: stories_${userId ?? 'me'}");

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

      await prefs.setString(_getStoriesKey(userId), storiesJson);
      debugPrint("💾 Saved ${_userStories.length} stories to storage");

      // Save timestamp for expiry
      await prefs.setString(
        _getTimestampKey(userId),
        DateTime.now().toIso8601String(),
      );
      debugPrint("⏰ Saved cache timestamp");

      // Save user info
      if (_username != null) {
        await prefs.setString(_getUsernameKey(userId), _username!);
        debugPrint("👤 Saved username: $_username");
      }

      if (_avatarUrl != null) {
        await prefs.setString(_getAvatarKey(userId), _avatarUrl!);
        debugPrint("🖼️ Saved avatar: $_avatarUrl");
      }

      debugPrint("✅ Stories saved to storage successfully");
      debugPrint("🏁 ===== SAVING STORIES TO STORAGE END =====\n");
    } catch (e) {
      debugPrint("❌ Error saving stories to storage: $e");
    }
  }
}
