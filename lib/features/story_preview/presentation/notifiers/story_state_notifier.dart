import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gruve_app/features/story_preview/domain/entities/story_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Story data model for organization
class StoryData {
  final String mediaPath;
  final DateTime createdAt;
  final String? id; // Story UUID for API calls

  const StoryData({required this.mediaPath, required this.createdAt, this.id});
}

/// Immutable state for [StoryStateNotifier]
class StoryState {
  final List<StoryData> userStories;
  final String? username;
  final String? avatarUrl;
  final bool isLoadingFromStorage;
  final String? currentUserId; // Track current user for cache isolation
  final StoryItem? currentStory; // Current story being viewed

  const StoryState({
    this.userStories = const [],
    this.username,
    this.avatarUrl,
    this.isLoadingFromStorage = false,
    this.currentUserId,
    this.currentStory,
  });

  bool get hasUserStory => userStories.isNotEmpty;

  List<String> get currentUserStoryMediaPaths =>
      userStories.map((s) => s.mediaPath).toList();

  List<String?> get currentUserStoryIds =>
      userStories.map((s) => s.id).toList();

  DateTime? get storyCreatedAt =>
      userStories.isNotEmpty ? userStories.first.createdAt : null;

  List<DateTime> get storyTimestamps =>
      userStories.map((s) => s.createdAt).toList();

  /// Get current story ID (UUID) for API calls
  String? get currentStoryId =>
      currentStory?.id ??
      (userStories.isNotEmpty ? userStories.first.id : null);

  /// Get story ID by media path
  String? getStoryIdByMediaPath(String mediaPath) {
    final story = userStories.firstWhere(
      (s) => s.mediaPath == mediaPath,
      orElse: () => StoryData(mediaPath: mediaPath, createdAt: DateTime.now()),
    );
    return story.id;
  }

  StoryState copyWith({
    List<StoryData>? userStories,
    String? username,
    bool clearUsername = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    bool? isLoadingFromStorage,
    String? currentUserId,
    bool clearCurrentUserId = false,
    StoryItem? currentStory,
    bool clearCurrentStory = false,
  }) {
    return StoryState(
      userStories: userStories ?? this.userStories,
      username: clearUsername ? null : (username ?? this.username),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      isLoadingFromStorage: isLoadingFromStorage ?? this.isLoadingFromStorage,
      currentUserId: clearCurrentUserId
          ? null
          : (currentUserId ?? this.currentUserId),
      currentStory: clearCurrentStory
          ? null
          : (currentStory ?? this.currentStory),
    );
  }
}

/// Riverpod Notifier replacing the legacy `StoryStateController` ChangeNotifier.
class StoryStateNotifier extends Notifier<StoryState> {
  // Cache expiry duration (5 minutes)
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Debounced save to prevent excessive storage writes
  Timer? _saveTimer;

  // Storage key helpers (per-user)
  String _getStoriesKey(String? userId) => 'stories_${userId ?? 'me'}';
  String _getUsernameKey(String? userId) => 'story_username_${userId ?? 'me'}';
  String _getAvatarKey(String? userId) => 'story_avatar_${userId ?? 'me'}';
  String _getTimestampKey(String? userId) =>
      'story_timestamp_${userId ?? 'me'}';

  @override
  StoryState build() {
    ref.onDispose(() {
      _saveTimer?.cancel();
    });

    return const StoryState();
  }

  /// Set current story being viewed
  void setCurrentStory(StoryItem? story) {
    AppLogger.d(
      '[StoryState] currentStory set: '
      'id=${story?.id ?? 'NULL'}, media=${story?.mediaUrl ?? 'NULL'}',
    );
    state = state.copyWith(
      currentStory: story,
      clearCurrentStory: story == null,
    );
  }

  void _debouncedSaveToStorage() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveStoriesToStorage(state.currentUserId);
    });
  }

  /// Sort stories by creation time (newest first)
  List<StoryData> _sortStoriesByTime(List<StoryData> stories) {
    final sorted = List<StoryData>.from(stories);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Update story status with validation
  Future<void> updateStory({String? mediaPath, DateTime? createdAt}) async {
    if (mediaPath == null || mediaPath.isEmpty) {
      await clearStory();
      return;
    }

    final currentStories = List<StoryData>.from(state.userStories);
    final existingIndex = currentStories.indexWhere(
      (story) => story.mediaPath == mediaPath,
    );

    if (existingIndex == -1) {
      currentStories.add(
        StoryData(mediaPath: mediaPath, createdAt: createdAt ?? DateTime.now()),
      );
    } else {
      currentStories[existingIndex] = StoryData(
        mediaPath: mediaPath,
        createdAt: createdAt ?? DateTime.now(),
      );
    }

    final sorted = _sortStoriesByTime(currentStories);
    state = state.copyWith(userStories: sorted);
    _debouncedSaveToStorage();
  }

  /// Add a new story to the list
  Future<void> addStory(String mediaPath, {DateTime? createdAt}) async {
    if (mediaPath.isNotEmpty) {
      final currentStories = List<StoryData>.from(state.userStories);
      currentStories.add(
        StoryData(mediaPath: mediaPath, createdAt: createdAt ?? DateTime.now()),
      );
      final sorted = _sortStoriesByTime(currentStories);
      state = state.copyWith(userStories: sorted);
      _debouncedSaveToStorage();
    }
  }

  /// Set user info from profile
  Future<void> setUserInfo({String? username, String? avatarUrl}) async {
    state = state.copyWith(
      username: username ?? state.username,
      avatarUrl: avatarUrl ?? state.avatarUrl,
    );
    _debouncedSaveToStorage();
  }

  /// Set stories from StoryItem list (replaces entire list)
  Future<void> setStoriesFromStoryItems(
    List<StoryItem> storyItems, {
    String? username,
    String? avatarUrl,
    String? userId,
  }) async {
    // Clear previous user's data if switching users
    if (userId != null &&
        state.currentUserId != null &&
        userId != state.currentUserId) {
      await _clearUserCache(state.currentUserId);
    }

    final newStories = <StoryData>[];
    for (final storyItem in storyItems) {
      newStories.add(
        StoryData(
          mediaPath: storyItem.mediaUrl,
          createdAt: storyItem.createdAt,
          id: storyItem.id, // Store the UUID
        ),
      );
    }

    final sorted = _sortStoriesByTime(newStories);

    // Set the first story as current if no current story is set
    StoryItem? nextCurrentStory = state.currentStory;
    if (nextCurrentStory == null && storyItems.isNotEmpty) {
      nextCurrentStory = storyItems.first;
      AppLogger.d(
        '[StoryState] currentStory set: '
        'id=${nextCurrentStory.id}, media=${nextCurrentStory.mediaUrl}',
      );
    }

    state = state.copyWith(
      currentUserId: userId,
      userStories: sorted,
      username: username ?? state.username,
      avatarUrl: avatarUrl ?? state.avatarUrl,
      currentStory: nextCurrentStory,
    );

    await _saveStoriesToStorage(userId);
  }

  /// Set stories from API response (replaces entire list)
  Future<void> setStoriesFromAPI(
    List<String> mediaPaths, {
    List<DateTime>? createdAts,
    List<String?>? storyIds,
    String? username,
    String? avatarUrl,
    String? userId,
  }) async {
    // Clear previous user's data if switching users
    if (userId != null &&
        state.currentUserId != null &&
        userId != state.currentUserId) {
      await _clearUserCache(state.currentUserId);
    }

    final newStories = <StoryData>[];
    for (int i = 0; i < mediaPaths.length; i++) {
      final mediaPath = mediaPaths[i];
      if (mediaPath.isNotEmpty) {
        newStories.add(
          StoryData(
            mediaPath: mediaPath,
            createdAt: createdAts != null && i < createdAts.length
                ? createdAts[i]
                : DateTime.now(),
            id: storyIds != null && i < storyIds.length ? storyIds[i] : null,
          ),
        );
      }
    }

    final sorted = _sortStoriesByTime(newStories);

    state = state.copyWith(
      currentUserId: userId,
      userStories: sorted,
      username: username ?? state.username,
      avatarUrl: avatarUrl ?? state.avatarUrl,
    );

    await _saveStoriesToStorage(userId);
  }

  /// Mark story as shared (simplified method)
  void markStoryAsShared(String mediaPath) {
    if (mediaPath.isNotEmpty) {
      updateStory(mediaPath: mediaPath);
    }
  }

  /// Clear story state
  Future<void> clearStory() async {
    state = state.copyWith(userStories: const [], clearCurrentStory: true);
    await _saveStoriesToStorage(state.currentUserId);
  }

  /// Reset controller state
  void reset() {
    clearStory();
  }

  /// Clear all story data including user info (for logout)
  Future<void> clearAllData() async {
    state = const StoryState();
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
    if (state.isLoadingFromStorage) return;
    state = state.copyWith(isLoadingFromStorage: true);
    await _loadStoriesFromStorage(userId);
  }

  /// Load stories from SharedPreferences
  Future<void> _loadStoriesFromStorage(String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache is expired
      if (await _isCacheExpired(userId)) {
        await _clearUserCache(userId);
        state = state.copyWith(isLoadingFromStorage: false);
        return;
      }

      // Load stories
      var loadedStories = <StoryData>[];
      final storiesJson = prefs.getString(_getStoriesKey(userId));
      if (storiesJson != null) {
        final List<dynamic> storiesList = jsonDecode(storiesJson);
        loadedStories = storiesList.map((storyJson) {
          final story = storyJson as Map<String, dynamic>;
          return StoryData(
            mediaPath: story['mediaPath'],
            createdAt: DateTime.parse(story['createdAt']),
            id: story['id']?.toString(),
          );
        }).toList();
      }

      // Load user info
      final loadedUsername = prefs.getString(_getUsernameKey(userId));
      final loadedAvatarUrl = prefs.getString(_getAvatarKey(userId));

      state = state.copyWith(
        userStories: loadedStories,
        username: loadedUsername,
        avatarUrl: loadedAvatarUrl,
        isLoadingFromStorage: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingFromStorage: false);
    }
  }

  /// Save stories to SharedPreferences
  Future<void> _saveStoriesToStorage(String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save stories
      final storiesJson = jsonEncode(
        state.userStories
            .map(
              (story) => {
                'mediaPath': story.mediaPath,
                'createdAt': story.createdAt.toIso8601String(),
                'id': story.id,
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
      if (state.username != null) {
        await prefs.setString(_getUsernameKey(userId), state.username!);
      }

      if (state.avatarUrl != null) {
        await prefs.setString(_getAvatarKey(userId), state.avatarUrl!);
      }
    } catch (e) {
      // Silently handle storage errors to avoid UI blocking
    }
  }
}

/// App-scoped provider for [StoryStateNotifier]
final storyStateNotifierProvider =
    NotifierProvider<StoryStateNotifier, StoryState>(StoryStateNotifier.new);
