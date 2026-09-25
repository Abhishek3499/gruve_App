import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/story_preview/data/datasource/story_service.dart';
import 'package:gruve_app/features/story_preview/domain/entities/story_model.dart';

/// Immutable state for [StoryViewsNotifier].
@immutable
class StoryViewsState {
  final String? storyId;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSuccess;
  final String message;
  final int viewsCount;
  final int currentPage;
  final bool hasNext;
  final List<StoryViewer> viewers;

  const StoryViewsState({
    this.storyId,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSuccess = false,
    this.message = '',
    this.viewsCount = 0,
    this.currentPage = 1,
    this.hasNext = false,
    this.viewers = const <StoryViewer>[],
  });

  StoryViewsState copyWith({
    String? storyId,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSuccess,
    String? message,
    int? viewsCount,
    int? currentPage,
    bool? hasNext,
    List<StoryViewer>? viewers,
  }) {
    return StoryViewsState(
      storyId: storyId ?? this.storyId,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSuccess: isSuccess ?? this.isSuccess,
      message: message ?? this.message,
      viewsCount: viewsCount ?? this.viewsCount,
      currentPage: currentPage ?? this.currentPage,
      hasNext: hasNext ?? this.hasNext,
      viewers: viewers ?? this.viewers,
    );
  }
}

/// Holds the viewer list + count for whichever own-story is currently being
/// watched, backing the "eye icon" viewers bar/sheet on [StoryViewScreen].
class StoryViewsNotifier extends Notifier<StoryViewsState> {
  StoryViewsNotifier({StoryService? service})
    : _service = service ?? StoryService();

  final StoryService _service;

  @override
  StoryViewsState build() {
    return const StoryViewsState();
  }

  void reset() {
    state = const StoryViewsState();
  }

  /// Fetches the views count + first page of viewers for [storyId].
  /// Safe to call repeatedly as the user swipes between their own stories.
  Future<void> fetchViews(String storyId) async {
    if (storyId.isEmpty) return;

    // Switching to a different story clears the previous list immediately
    // so the sheet/bar never shows stale viewers.
    if (state.storyId != storyId) {
      state = StoryViewsState(storyId: storyId, isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final response = await _service.fetchStoryViews(storyId, page: 1);

      if (state.storyId != storyId) return; // story changed while awaiting

      if (response.success) {
        state = state.copyWith(
          isSuccess: true,
          message: response.message,
          viewsCount: response.data.viewsCount,
          currentPage: response.data.page,
          hasNext: response.data.hasNext,
          viewers: List<StoryViewer>.unmodifiable(response.data.viewers),
        );
      } else {
        state = state.copyWith(isSuccess: false, message: response.message);
      }
    } catch (e) {
      AppLogger.d('[StoryViewsNotifier] fetchViews error: $e');
      if (state.storyId == storyId) {
        state = state.copyWith(
          isSuccess: false,
          message: 'Unable to load viewers',
        );
      }
    } finally {
      if (state.storyId == storyId) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Loads the next page of viewers for the story currently held in state.
  Future<void> loadMore() async {
    final storyId = state.storyId;
    if (storyId == null || storyId.isEmpty) return;
    if (state.isLoadingMore || !state.hasNext) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _service.fetchStoryViews(storyId, page: nextPage);

      if (state.storyId != storyId) return;

      if (response.success) {
        state = state.copyWith(
          viewsCount: response.data.viewsCount,
          currentPage: response.data.page,
          hasNext: response.data.hasNext,
          viewers: List<StoryViewer>.unmodifiable([
            ...state.viewers,
            ...response.data.viewers,
          ]),
        );
      }
    } catch (e) {
      AppLogger.d('[StoryViewsNotifier] loadMore error: $e');
    } finally {
      if (state.storyId == storyId) {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }
}

final storyViewsNotifierProvider =
    NotifierProvider<StoryViewsNotifier, StoryViewsState>(
      StoryViewsNotifier.new,
    );
