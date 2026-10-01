import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/search/data/datasource/explore_stories_service.dart';
import 'package:gruve_app/features/search/domain/entities/explore_story_model.dart';

@immutable
class ExploreStoriesState {
  const ExploreStoriesState({
    this.data = const ExploreStoriesData(),
    this.isLoading = false,
    this.hasLoaded = false,
    this.error,
  });

  final ExploreStoriesData data;
  final bool isLoading;
  final bool hasLoaded;
  final String? error;

  ExploreStoriesState copyWith({
    ExploreStoriesData? data,
    bool? isLoading,
    bool? hasLoaded,
    String? error,
    bool clearError = false,
  }) {
    return ExploreStoriesState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExploreStoriesNotifier extends Notifier<ExploreStoriesState> {
  final ExploreStoriesService _service = ExploreStoriesService();

  @override
  ExploreStoriesState build() => const ExploreStoriesState();

  /// Loads the tray. Pass [silent] to refresh without flipping to a loading
  /// state (used after a story is watched, so the rows don't flash).
  Future<void> load({bool silent = false}) async {
    if (state.isLoading) return;
    if (!silent) state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await _service.fetchStories();
      state = ExploreStoriesState(data: data, hasLoaded: true);
    } catch (e) {
      AppLogger.d('[ExploreStoriesNotifier] load failed: $e');
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        error: 'Failed to load stories',
      );
    }
  }

  void reset() => state = const ExploreStoriesState();
}

final exploreStoriesNotifierProvider =
    NotifierProvider<ExploreStoriesNotifier, ExploreStoriesState>(
      ExploreStoriesNotifier.new,
    );
