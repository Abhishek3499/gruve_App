import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/highlights_create/api/highlight_create_service.dart';

class HighlightCreateController extends GetxController {
  static const String duplicateStoryMessage =
      'Story already added to this highlight';

  final HighlightCreateService _service = HighlightCreateService();
  final HighlightController _highlightController =
      Get.find<HighlightController>();

  final RxBool isLoading = false.obs;
  final RxString message = ''.obs;
  final RxBool isSuccess = false.obs;

  bool isSubmitting = false;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[Highlight] Controller initialized');
  }

  void reset() {
    debugPrint('[Highlight] Resetting controller state');
    message.value = '';
    isSuccess.value = false;
    isLoading.value = false;
    isSubmitting = false;
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
        message.value = 'Story ID is required';
        isSuccess.value = false;
        debugPrint('[Highlight] API CALL END');
        return;
      }

      final isUpdate = highlightId != null && highlightId.isNotEmpty;
      if (!isUpdate && (title == null || title.isEmpty)) {
        debugPrint('[Highlight] Title is required for creating new highlight');
        message.value = 'Title is required for creating new highlight';
        isSuccess.value = false;
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
        message.value = duplicateStoryMessage;
        isSuccess.value = false;
        debugPrint('[Highlight] API CALL END');
        return;
      }

      isSubmitting = true;
      isLoading.value = true;
      isSuccess.value = false;
      message.value = '';

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

        message.value = isUpdate
            ? 'Story added to highlight successfully!'
            : 'New highlight created successfully!';
        isSuccess.value = true;

        debugPrint('[Highlight] Refreshing highlights list');
        await _highlightController.fetchMyHighlights();

        HighlightStateManager.ensureRegistered();
        await HighlightStateManager.instance.markStoryAsHighlighted(storyId);
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

        message.value = response.message.isNotEmpty
            ? response.message
            : 'Operation failed';
        isSuccess.value = false;
      }
    } catch (e) {
      debugPrint('[Highlight] Failed with exception');
      debugPrint('[Highlight] Error: $e');

      message.value = 'Something went wrong';
      isSuccess.value = false;
    } finally {
      isSubmitting = false;
      isLoading.value = false;
      debugPrint('[Highlight] API CALL END');
    }
  }
}
