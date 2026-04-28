import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

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

  // Debounced save to prevent excessive storage writes
  Timer? _saveTimer;
  
  void _debouncedSaveToStorage() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveStoriesToStorage(_currentUserId);
    });
  }

  /// Update story status with validation
  Future<void> updateStory({String? mediaPath, DateTime? createdAt}) async {
    if (mediaPath == null || mediaPath.isEmpty) {
      clearStory();
      return;
    }

    // Check if story already exists to avoid duplicates
    final existingIndex = _userStories.indexWhere(
      (story) => story.mediaPath == mediaPath,
    );

    if (existingIndex == -1) {
      // Add new story if it doesn't exist
      _userStories.add(
        StoryData(mediaPath: mediaPath, createdAt: createdAt ?? DateTime.now()),
      );
    } else {
      // Update existing story timestamp
      _userStories[existingIndex] = StoryData(
        mediaPath: mediaPath,
        createdAt: createdAt ?? DateTime.now(),
      );
    }

    _sortStoriesByTime();
    notifyListeners();
    // Debounce storage save to avoid excessive writes
    _debouncedSaveToStorage();
  }

  /// Add a new story to the list
  Future<void> addStory(String mediaPath, {DateTime? createdAt}) async {
    if (mediaPath.isNotEmpty) {
      _userStories.add(
        StoryData(mediaPath: mediaPath, createdAt: createdAt ?? DateTime.now()),
      );
      _sortStoriesByTime();
      notifyListeners();
      // Debounce storage save to avoid excessive writes
      _debouncedSaveToStorage();
    }
  }

  /// Set user info from profile
  Future<void> setUserInfo({String? username, String? avatarUrl}) async {
    _username = username;
    _avatarUrl = avatarUrl;
    notifyListeners();
    // Debounce storage save to avoid excessive writes
    _debouncedSaveToStorage();
  }

  /// Set stories from API response (replaces entire list)
  Future<void> setStoriesFromAPI(
    List<String> mediaPaths, {
    List<DateTime>? createdAts,
    String? username,
    String? avatarUrl,
    String? userId,
  }) async {
    // Clear previous user's data if switching users
    if (userId != null && _currentUserId != null && userId != _currentUserId) {
      await _clearUserCache(_currentUserId);
    }

    _currentUserId = userId;
    _userStories.clear();

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
      }
    }

    _sortStoriesByTime();
    notifyListeners();
    await _saveStoriesToStorage(userId);
  }

  /// Sort stories by creation time (newest first)
  void _sortStoriesByTime() {
    _userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Mark story as shared (simplified method)
  void markStoryAsShared(String mediaPath) {
    if (mediaPath.isNotEmpty) {
      updateStory(mediaPath: mediaPath);
    }
  }

  /// Clear story state
  Future<void> clearStory() async {
    _userStories = [];
    notifyListeners();
    await _saveStoriesToStorage(_currentUserId);
  }

  /// Reset controller state
  void reset() {
    clearStory();
  }

  /// Clear all story data including user info (for logout)
  Future<void> clearAllData() async {
    _userStories = [];
    _username = null;
    _avatarUrl = null;
    _currentUserId = null;
    notifyListeners();
    await _clearAllCache();
  }

  /// Clear cache for a specific user
  Future<void> _clearUserCache(String? userId) async {
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getStoriesKey(userId));
    await prefs.remove(_getUsernameKey(userId));
    await prefs.remove(_getAvatarKey(userId));
    await prefs.remove(_getTimestampKey(userId));
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
  }

  /// Check if cache is expired
  Future<bool> _isCacheExpired(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(_getTimestampKey(userId));

    if (timestampStr == null) return true;

    final timestamp = DateTime.tryParse(timestampStr);
    if (timestamp == null) return true;

    return DateTime.now().difference(timestamp) > _cacheExpiry;
  }

  // 💾 PERSISTENT STORAGE METHODS

  /// Load stories from SharedPreferences (public method)
  Future<void> loadStoriesFromStorage(String? userId) async {
    if (_isLoadingFromStorage) return;
    _isLoadingFromStorage = true;
    notifyListeners();
    await _loadStoriesFromStorage(userId);
  }

  /// Load stories from SharedPreferences
  Future<void> _loadStoriesFromStorage(String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache is expired
      if (await _isCacheExpired(userId)) {
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
      }

      // Load user info
      _username = prefs.getString(_getUsernameKey(userId));
      _avatarUrl = prefs.getString(_getAvatarKey(userId));

      _isLoadingFromStorage = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFromStorage = false;
      notifyListeners();
    }
  }

  /// Save stories to SharedPreferences
  Future<void> _saveStoriesToStorage(String? userId) async {
    try {
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

      // Save timestamp for expiry
      await prefs.setString(
        _getTimestampKey(userId),
        DateTime.now().toIso8601String(),
      );

      // Save user info
      if (_username != null) {
        await prefs.setString(_getUsernameKey(userId), _username!);
      }

      if (_avatarUrl != null) {
        await prefs.setString(_getAvatarKey(userId), _avatarUrl!);
      }
    } catch (e) {
      // Silently handle storage errors to avoid UI blocking
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
