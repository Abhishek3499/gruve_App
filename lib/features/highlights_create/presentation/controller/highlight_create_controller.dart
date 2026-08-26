import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/highlights/presentation/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/presentation/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';
import 'package:gruve_app/features/highlights_create/data/datasource/highlight_create_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class HighlightCreateController extends ChangeNotifier {
  static const String duplicateStoryMessage =
      'Story already added to this highlight';

  HighlightCreateController({
    required HighlightController highlightController,
    required HighlightStateManager stateManager,
    HighlightCreateService? service,
  }) : _highlightController = highlightController,
       _stateManager = stateManager,
       _service = service ?? HighlightCreateService() {
    AppLogger.d('[Highlight] Controller initialized');
  }

  final HighlightCreateService _service;
  final HighlightController _highlightController;
  final HighlightStateManager _stateManager;

  bool isLoading = false;
  String message = '';
  bool isSuccess = false;

  bool isSubmitting = false;

  void reset() {
    AppLogger.d('[Highlight] Resetting controller state');
    message = '';
    isSuccess = false;
    isLoading = false;
    isSubmitting = false;
    notifyListeners();
  }

  HighlightModel? _findHighlight(String? highlightId) {
    if (highlightId == null || highlightId.isEmpty) return null;

    try {
      return _highlightController.highlights.firstWhere(
        (highlight) => highlight.id == highlightId,
      );
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
    if (isSubmitting) {
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
        message = 'Story ID is required';
        isSuccess = false;
        notifyListeners();
        AppLogger.d('[Highlight] API CALL END');
        return;
      }

      final isUpdate = highlightId != null && highlightId.isNotEmpty;
      if (!isUpdate && (title == null || title.isEmpty)) {
        AppLogger.d('[Highlight] Title is required for creating new highlight');
        message = 'Title is required for creating new highlight';
        isSuccess = false;
        notifyListeners();
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
        message = duplicateStoryMessage;
        isSuccess = false;
        notifyListeners();
        AppLogger.d('[Highlight] API CALL END');
        return;
      }

      isSubmitting = true;
      isLoading = true;
      isSuccess = false;
      message = '';
      notifyListeners();

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

        message = isUpdate
            ? 'Story added to highlight successfully!'
            : 'New highlight created successfully!';
        isSuccess = true;

        AppLogger.d('[Highlight] Refreshing highlights list');
        await _highlightController.fetchMyHighlights();

        await _stateManager.markStoryAsHighlighted(storyId);
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

        message = response.message.isNotEmpty
            ? response.message
            : 'Operation failed';
        isSuccess = false;
      }
    } catch (e) {
      AppLogger.d('[Highlight] Failed with exception');
      AppLogger.d('[Highlight] Error: $e');

      message = 'Something went wrong';
      isSuccess = false;
    } finally {
      isSubmitting = false;
      isLoading = false;
      notifyListeners();
      AppLogger.d('[Highlight] API CALL END');
    }
  }
}
