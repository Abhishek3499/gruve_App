import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/highlights/data/datasource/highlight_create_service.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_controller_notifier.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_state_notifier.dart';
import 'package:gruve_app/features/profile/presentation/notifiers/profile_notifier.dart';

/// Immutable state for [HighlightCreateNotifier].
@immutable
class HighlightCreateState {
  final bool isLoading;
  final String message;
  final bool isSuccess;
  final bool isSubmitting;

  const HighlightCreateState({
    this.isLoading = false,
    this.message = '',
    this.isSuccess = false,
    this.isSubmitting = false,
  });

  HighlightCreateState copyWith({
    bool? isLoading,
    String? message,
    bool? isSuccess,
    bool? isSubmitting,
  }) {
    return HighlightCreateState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      isSuccess: isSuccess ?? this.isSuccess,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighlightCreateState &&
        other.isLoading == isLoading &&
        other.message == message &&
        other.isSuccess == isSuccess &&
        other.isSubmitting == isSubmitting;
  }

  @override
  int get hashCode => Object.hash(isLoading, message, isSuccess, isSubmitting);
}

/// Riverpod Notifier replacing the legacy [HighlightCreateController] ChangeNotifier.
class HighlightCreateNotifier extends Notifier<HighlightCreateState> {
  static const String duplicateStoryMessage =
      'Story already added to this highlight';

  HighlightCreateNotifier({HighlightCreateService? service})
    : _service = service ?? HighlightCreateService();

  final HighlightCreateService _service;

  @override
  HighlightCreateState build() {
    AppLogger.d('[Highlight] Controller initialized');
    return const HighlightCreateState();
  }

  bool get isLoading => state.isLoading;
  String get message => state.message;
  bool get isSuccess => state.isSuccess;
  bool get isSubmitting => state.isSubmitting;

  void reset() {
    AppLogger.d('[Highlight] Resetting controller state');
    state = const HighlightCreateState();
  }

  HighlightModel? _findHighlight(String? highlightId) {
    if (highlightId == null || highlightId.isEmpty) return null;

    try {
      final highlights = ref.read(highlightControllerProvider).highlights;
      return highlights.firstWhere((highlight) => highlight.id == highlightId);
    } catch (_) {
      return null;
    }
  }

  bool isStoryAlreadyInHighlight({
    required String highlightId,
    required String storyId,
  }) {
    return _findHighlight(highlightId)?.containsStory(storyId) ?? false;
  }

  Future<void> addStoryToHighlight({
    String? highlightId,
    required String storyId,
    String? title,
  }) async {
    if (state.isSubmitting) {
      AppLogger.d(
        '[Highlight] API already in progress, skipping duplicate call',
      );
      return;
    }

    AppLogger.d('[Highlight] User triggered action');
    AppLogger.d('[Highlight] API CALL START');

    try {
      if (storyId.isEmpty) {
        AppLogger.d('[Highlight] Story ID cannot be empty');
        state = state.copyWith(
          message: 'Story ID is required',
          isSuccess: false,
        );
        AppLogger.d('[Highlight] API CALL END');
        return;
      }

      final isUpdate = highlightId != null && highlightId.isNotEmpty;
      if (!isUpdate && (title == null || title.isEmpty)) {
        AppLogger.d('[Highlight] Title is required for creating new highlight');
        state = state.copyWith(
          message: 'Title is required for creating new highlight',
          isSuccess: false,
        );
        AppLogger.d('[Highlight] API CALL END');
        return;
      }

      AppLogger.d(
        '[Highlight] Add attempt: highlight_id=${highlightId ?? 'NEW'}, '
        'story_id=$storyId',
      );

      if (isUpdate &&
          isStoryAlreadyInHighlight(
            highlightId: highlightId,
            storyId: storyId,
          )) {
        AppLogger.d(
          '[Highlight] Duplicate detected: highlight_id=$highlightId, '
          'story_id=$storyId',
        );
        state = state.copyWith(
          message: duplicateStoryMessage,
          isSuccess: false,
        );
        AppLogger.d('[Highlight] API CALL END');
        return;
      }

      state = state.copyWith(
        isSubmitting: true,
        isLoading: true,
        isSuccess: false,
        message: '',
      );

      AppLogger.d(
        isUpdate
            ? '[Highlight] Updating existing highlight'
            : '[Highlight] Creating new highlight',
      );

      AppLogger.d('[Highlight] Sending Data:');
      AppLogger.d('[Highlight] highlightId: $highlightId');
      AppLogger.d('[Highlight] storyId: $storyId');
      AppLogger.d('[Highlight] title: $title');

      final response = await _service.createOrUpdateHighlight(
        highlightId: highlightId,
        title: title ?? '',
        storyIds: [storyId],
      );

      if (response.success) {
        AppLogger.d('[Highlight] Success');
        AppLogger.d('[Highlight] highlightId: ${response.data.id}');
        AppLogger.d('[Highlight] title: ${response.data.title}');
        AppLogger.d('[Highlight] storiesCount: ${response.data.storiesCount}');

        state = state.copyWith(
          message: isUpdate
              ? 'Story added to highlight successfully!'
              : 'New highlight created successfully!',
          isSuccess: true,
        );

        final targetHighlightId =
            (highlightId != null && highlightId.isNotEmpty)
            ? highlightId
            : (response.data.id.isNotEmpty ? response.data.id : null);

        // 1. Invalidate HTTP cache for highlights so network fetch gets fresh data
        await CacheManager().invalidatePattern('highlights');
        if (targetHighlightId != null) {
          await CacheInvalidationService().onHighlightUpdated(
            targetHighlightId,
          );
        }

        // 2. Clear in-memory highlight stories cache so viewer fetches fresh stories
        if (targetHighlightId != null) {
          ref
              .read(highlightControllerProvider.notifier)
              .invalidateHighlightStories(targetHighlightId);
        }

        // 3. Refresh highlights list in highlight controller
        AppLogger.d('[Highlight] Refreshing highlights list');
        await ref
            .read(highlightControllerProvider.notifier)
            .fetchMyHighlights();

        // 4. Update ProfileNotifier with the newly fetched highlights so Profile screen updates immediately
        final freshHighlights = ref
            .read(highlightControllerProvider)
            .highlights;
        ref
            .read(profileNotifierProvider.notifier)
            .updateHighlights(freshHighlights);

        await ref
            .read(highlightStateNotifierProvider.notifier)
            .markStoryAsHighlighted(storyId);
      } else {
        if (response.message == duplicateStoryMessage ||
            response.statusCode == 400 ||
            response.statusCode == 409) {
          AppLogger.d(
            '[Highlight] Duplicate detected by API: '
            'highlight_id=${highlightId ?? 'NEW'}, story_id=$storyId',
          );
        } else {
          AppLogger.d('[Highlight] Failed - API returned false');
        }

        state = state.copyWith(
          message: response.message.isNotEmpty
              ? response.message
              : 'Operation failed',
          isSuccess: false,
        );
      }
    } catch (e) {
      AppLogger.d('[Highlight] Failed with exception');
      AppLogger.d('[Highlight] Error: $e');

      state = state.copyWith(message: 'Something went wrong', isSuccess: false);
    } finally {
      state = state.copyWith(isSubmitting: false, isLoading: false);
      AppLogger.d('[Highlight] API CALL END');
    }
  }
}

/// App-scoped provider for [HighlightCreateNotifier].
final highlightCreateNotifierProvider =
    NotifierProvider<HighlightCreateNotifier, HighlightCreateState>(
      HighlightCreateNotifier.new,
    );
