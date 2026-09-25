import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/story_preview/domain/entities/story_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Story data model for organization
class StoryData {
  final String mediaPath;
  final DateTime createdAt;
  final String? id; // Story UUID for API calls
  final String visibility;

  const StoryData({
    required this.mediaPath,
    required this.createdAt,
    this.id,
    this.visibility = 'public',
  });
}

/// Immutable state for [StoryStateNotifier].
///
/// This is in-memory only for the lifetime of the app session — stories are
/// always fetched fresh from the API and are never persisted to disk, so a
/// previously viewed user's stories can never leak into another user's view.
class StoryState {
  final List<StoryData> userStories;
  final String? username;
  final String? avatarUrl;
  final String? currentUserId; // Whose stories are currently held in memory
  final StoryItem? currentStory; // Current story being viewed

  const StoryState({
    this.userStories = const [],
    this.username,
    this.avatarUrl,
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

  /// Get story visibility ('public' / 'close_friends') by media path
  String getVisibilityByMediaPath(String mediaPath) {
    final story = userStories.firstWhere(
      (s) => s.mediaPath == mediaPath,
      orElse: () => StoryData(mediaPath: mediaPath, createdAt: DateTime.now()),
    );
    return story.visibility;
  }

  StoryState copyWith({
    List<StoryData>? userStories,
    String? username,
    bool clearUsername = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    String? currentUserId,
    bool clearCurrentUserId = false,
    StoryItem? currentStory,
    bool clearCurrentStory = false,
  }) {
    return StoryState(
      userStories: userStories ?? this.userStories,
      username: clearUsername ? null : (username ?? this.username),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
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
///
/// Holds whatever stories were last fetched from the API, purely in memory —
/// there is no SharedPreferences/disk cache here on purpose, so the story
/// viewer always reflects what the API actually returned.
class StoryStateNotifier extends Notifier<StoryState> {
  @override
  StoryState build() {
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

  /// Sort stories by creation time (newest first)
  List<StoryData> _sortStoriesByTime(List<StoryData> stories) {
    final sorted = List<StoryData>.from(stories);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Update story status with validation
  void updateStory({String? mediaPath, DateTime? createdAt}) {
    if (mediaPath == null || mediaPath.isEmpty) {
      clearStory();
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
  }

  /// Add a new story to the list
  void addStory(String mediaPath, {DateTime? createdAt}) {
    if (mediaPath.isNotEmpty) {
      final currentStories = List<StoryData>.from(state.userStories);
      currentStories.add(
        StoryData(mediaPath: mediaPath, createdAt: createdAt ?? DateTime.now()),
      );
      final sorted = _sortStoriesByTime(currentStories);
      state = state.copyWith(userStories: sorted);
    }
  }

  /// Set user info from profile
  Future<void> setUserInfo({String? username, String? avatarUrl}) async {
    state = state.copyWith(
      username: username ?? state.username,
      avatarUrl: avatarUrl ?? state.avatarUrl,
    );
  }

  /// Set stories from StoryItem list (replaces entire list). Always called
  /// with the [userId] whose stories were just fetched from the API, so the
  /// in-memory state is stamped with that user and never mixed with another.
  Future<void> setStoriesFromStoryItems(
    List<StoryItem> storyItems, {
    String? username,
    String? avatarUrl,
    String? userId,
  }) async {
    final newStories = <StoryData>[];
    for (final storyItem in storyItems) {
      newStories.add(
        StoryData(
          mediaPath: storyItem.mediaUrl,
          createdAt: storyItem.createdAt,
          id: storyItem.id, // Store the UUID
          visibility: storyItem.visibility,
        ),
      );
    }

    final sorted = _sortStoriesByTime(newStories);

    state = state.copyWith(
      currentUserId: userId,
      clearCurrentUserId: userId == null,
      userStories: sorted,
      username: username,
      clearUsername: username == null,
      avatarUrl: avatarUrl,
      clearAvatarUrl: avatarUrl == null,
      currentStory: storyItems.isNotEmpty ? storyItems.first : null,
      clearCurrentStory: storyItems.isEmpty,
    );
  }

  /// Mark story as shared (simplified method)
  void markStoryAsShared(String mediaPath) {
    if (mediaPath.isNotEmpty) {
      updateStory(mediaPath: mediaPath);
    }
  }

  /// Clear story state
  void clearStory() {
    state = state.copyWith(userStories: const [], clearCurrentStory: true);
  }

  /// Reset controller state
  void reset() {
    clearStory();
  }

  /// Clear all story data (e.g. on logout)
  void clearAllData() {
    state = const StoryState();
  }
}

/// App-scoped provider for [StoryStateNotifier]
final storyStateNotifierProvider =
    NotifierProvider<StoryStateNotifier, StoryState>(StoryStateNotifier.new);
