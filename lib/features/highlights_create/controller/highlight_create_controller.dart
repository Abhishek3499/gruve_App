import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/highlights_create/api/highlight_create_service.dart';

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
    debugPrint('[Highlight] Controller initialized');
  }

  final HighlightCreateService _service;
  final HighlightController _highlightController;
  final HighlightStateManager _stateManager;

  bool isLoading = false;
  String message = '';
  bool isSuccess = false;

  bool isSubmitting = false;

  void reset() {
    debugPrint('[Highlight] Resetting controller state');
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
      debugPrint(
        '[Highlight] API already in progress, skipping duplicate call',
      );
      return;
    }

    debugPrint('[Highlight] User triggered action');
    debugPrint('[Highlight] API CALL START');

    try {
      if (storyId.isEmpty) {
        debugPrint('[Highlight] Story ID cannot be empty');
        message = 'Story ID is required';
        isSuccess = false;
        notifyListeners();
        debugPrint('[Highlight] API CALL END');
        return;
      }

      final isUpdate = highlightId != null && highlightId.isNotEmpty;
      if (!isUpdate && (title == null || title.isEmpty)) {
        debugPrint('[Highlight] Title is required for creating new highlight');
        message = 'Title is required for creating new highlight';
        isSuccess = false;
        notifyListeners();
        debugPrint('[Highlight] API CALL END');
        return;
      }

      debugPrint(
        '[Highlight] Add attempt: highlight_id=${highlightId ?? 'NEW'}, '
        'story_id=$storyId',
      );

      if (isUpdate &&
          isStoryAlreadyInHighlight(
            highlightId: highlightId,
            storyId: storyId,
          )) {
        debugPrint(
          '[Highlight] Duplicate detected: highlight_id=$highlightId, '
          'story_id=$storyId',
        );
        message = duplicateStoryMessage;
        isSuccess = false;
        notifyListeners();
        debugPrint('[Highlight] API CALL END');
        return;
      }

      isSubmitting = true;
      isLoading = true;
      isSuccess = false;
      message = '';
      notifyListeners();

      debugPrint(
        isUpdate
            ? '[Highlight] Updating existing highlight'
            : '[Highlight] Creating new highlight',
      );

      debugPrint('[Highlight] Sending Data:');
      debugPrint('[Highlight] highlightId: $highlightId');
      debugPrint('[Highlight] storyId: $storyId');
      debugPrint('[Highlight] title: $title');

      final response = await _service.createOrUpdateHighlight(
        highlightId: highlightId,
        title: title ?? '',
        storyIds: [storyId],
      );

      if (response.success) {
        debugPrint('[Highlight] Success');
        debugPrint('[Highlight] highlightId: ${response.data.id}');
        debugPrint('[Highlight] title: ${response.data.title}');
        debugPrint('[Highlight] storiesCount: ${response.data.storiesCount}');

        message = isUpdate
            ? 'Story added to highlight successfully!'
            : 'New highlight created successfully!';
        isSuccess = true;

        debugPrint('[Highlight] Refreshing highlights list');
        await _highlightController.fetchMyHighlights();

        await _stateManager.markStoryAsHighlighted(storyId);
      } else {
        if (response.message == duplicateStoryMessage ||
            response.statusCode == 400 ||
            response.statusCode == 409) {
          debugPrint(
            '[Highlight] Duplicate detected by API: '
            'highlight_id=${highlightId ?? 'NEW'}, story_id=$storyId',
          );
        } else {
          debugPrint('[Highlight] Failed - API returned false');
        }

        message = response.message.isNotEmpty
            ? response.message
            : 'Operation failed';
        isSuccess = false;
      }
    } catch (e) {
      debugPrint('[Highlight] Failed with exception');
      debugPrint('[Highlight] Error: $e');

      message = 'Something went wrong';
      isSuccess = false;
    } finally {
      isSubmitting = false;
      isLoading = false;
      notifyListeners();
      debugPrint('[Highlight] API CALL END');
    }
  }
}
