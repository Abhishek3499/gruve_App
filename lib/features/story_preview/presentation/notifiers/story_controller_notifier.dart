import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_state_notifier.dart';
import 'package:gruve_app/features/story_preview/data/datasource/story_service.dart';
import 'package:gruve_app/features/story_preview/domain/entities/story_model.dart';

/// Immutable state for [StoryControllerNotifier].
@immutable
class StoryControllerState {
  final bool isLoading;
  final String message;
  final bool isSuccess;
  final List<StoryItem> stories;
  final int totalCount;
  final int currentPage;
  final bool hasNext;

  const StoryControllerState({
    this.isLoading = false,
    this.message = '',
    this.isSuccess = false,
    this.stories = const <StoryItem>[],
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasNext = false,
  });

  StoryControllerState copyWith({
    bool? isLoading,
    String? message,
    bool? isSuccess,
    List<StoryItem>? stories,
    int? totalCount,
    int? currentPage,
    bool? hasNext,
  }) {
    return StoryControllerState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      isSuccess: isSuccess ?? this.isSuccess,
      stories: stories ?? this.stories,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasNext: hasNext ?? this.hasNext,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoryControllerState &&
        other.isLoading == isLoading &&
        other.message == message &&
        other.isSuccess == isSuccess &&
        listEquals(other.stories, stories) &&
        other.totalCount == totalCount &&
        other.currentPage == currentPage &&
        other.hasNext == hasNext;
  }

  @override
  int get hashCode => Object.hash(
    isLoading,
    message,
    isSuccess,
    Object.hashAll(stories),
    totalCount,
    currentPage,
    hasNext,
  );
}

/// Riverpod Notifier replacing the legacy [StoryController] ChangeNotifier.
class StoryControllerNotifier extends Notifier<StoryControllerState> {
  StoryControllerNotifier({StoryService? service})
    : _service = service ?? StoryService();

  final StoryService _service;

  @override
  StoryControllerState build() {
    return const StoryControllerState();
  }

  // Getters for backwards compatibility / imperative reads
  bool get isLoading => state.isLoading;
  String get message => state.message;
  bool get isSuccess => state.isSuccess;
  List<StoryItem> get stories => state.stories;
  int get totalCount => state.totalCount;
  int get currentPage => state.currentPage;
  bool get hasNext => state.hasNext;

  void reset() {
    state = const StoryControllerState();
  }

  Future<void> createStory({
    required String caption,
    required String mediaPath,
    bool isMuted = false,
  }) async {
    try {
      AppLogger.d("\n🎬 ===== CONTROLLER START =====");
      AppLogger.d("⏳ Loading started...");
      AppLogger.d("📝 Caption: $caption");
      AppLogger.d("📁 Media Path: $mediaPath");

      state = state.copyWith(isLoading: true, isSuccess: false, message: "");

      final response = await _service.createStory(
        caption: caption,
        mediaPath: mediaPath,
        isMuted: isMuted,
      );

      AppLogger.d("📥 API Response: ${response.message}");

      state = state.copyWith(
        message: response.message,
        isSuccess: response.success,
      );

      if (kDebugMode) {
        if (state.isSuccess) {
          AppLogger.d("✅ Story created successfully 🎉");
        } else {
          AppLogger.d("❌ Story failed: ${response.message}");
        }
      }
    } catch (e) {
      AppLogger.d("💥 Controller error: $e");

      state = state.copyWith(
        message: "Something went wrong 😓",
        isSuccess: false,
      );
    } finally {
      state = state.copyWith(isLoading: false);

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

      state = state.copyWith(isLoading: true, isSuccess: false, message: "");

      final response = await _service.fetchStories(
        userId: userId,
        page: page,
        limit: limit,
      );

      AppLogger.d("📥 API Response: ${response.message}");

      if (response.success) {
        AppLogger.d("✅ Stories fetched successfully 🎉");

        final newStories = List<StoryItem>.unmodifiable(response.data.stories);
        final newTotalCount = response.data.count;
        final newCurrentPage = response.data.page;
        final newHasNext = response.data.hasNext;

        state = state.copyWith(
          message: response.message,
          isSuccess: response.success,
          stories: newStories,
          totalCount: newTotalCount,
          currentPage: newCurrentPage,
          hasNext: newHasNext,
        );

        for (final story in newStories) {
          if (story.isHighlighted == true) {
            await ref
                .read(highlightStateNotifierProvider.notifier)
                .markStoryAsHighlighted(story.id);
          }
        }

        AppLogger.d("📚 Total stories: ${newStories.length}");
        AppLogger.d("🔢 Total count: $newTotalCount");
        AppLogger.d("📄 Current page: $newCurrentPage");
        AppLogger.d("➡️ Has next: $newHasNext");
      } else {
        AppLogger.d("❌ Stories fetch failed: ${response.message}");
        state = state.copyWith(
          message: response.message,
          isSuccess: response.success,
        );
      }
    } catch (e) {
      AppLogger.d("💥 Controller error: $e");

      state = state.copyWith(
        message: "Something went wrong 😓",
        isSuccess: false,
      );
    } finally {
      state = state.copyWith(isLoading: false);

      AppLogger.d("🏁 ===== FETCH STORIES CONTROLLER END =====\n");
    }
  }
}

final storyControllerProvider =
    NotifierProvider<StoryControllerNotifier, StoryControllerState>(
      StoryControllerNotifier.new,
    );
