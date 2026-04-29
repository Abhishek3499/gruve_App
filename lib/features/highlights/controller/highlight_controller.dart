import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:gruve_app/features/highlights/api/highlight_service.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';

class HighlightController extends GetxController {
  final HighlightService _service = HighlightService();

  final RxBool isLoading = false.obs;
  final RxString message = ''.obs;
  final RxBool isSuccess = false.obs;

  final RxList<HighlightModel> highlights = <HighlightModel>[].obs;
  final RxInt totalCount = 0.obs;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<void> reset() async {
    message.value = '';
    isSuccess.value = false;
    highlights.clear();
    totalCount.value = 0;
    HighlightStateManager.ensureRegistered();
    await HighlightStateManager.instance.clearAllHighlightedStories();
  }

  Future<void> fetchMyHighlights() async {
    try {
      _log('[HighlightController] fetchMyHighlights start');

      isLoading.value = true;
      isSuccess.value = false;
      message.value = '';

      final response = await _service.fetchMyHighlights();

      _log('[HighlightController] API success: ${response.success}');
      _log(
        '[HighlightController] Highlights total: '
        '${response.data.highlights.length}',
      );

      message.value = response.success
          ? 'Highlights fetched successfully'
          : 'Failed to fetch highlights';
      isSuccess.value = response.success;

      if (response.success) {
        highlights
          ..clear()
          ..addAll(response.data.highlights);
        totalCount.value = response.data.highlights.length;

        for (final highlight in highlights) {
          _log(
            '[HighlightController] Highlight: ${highlight.title}, '
            'stories=${highlight.stories.map((story) => story.id).toList()}',
          );
        }

        HighlightStateManager.ensureRegistered();
      }
    } catch (e) {
      _log('[HighlightController] error: $e');
      message.value = 'Something went wrong';
      isSuccess.value = false;
    } finally {
      isLoading.value = false;
      _log('[HighlightController] fetchMyHighlights end');
    }
  }

  Future<HighlightModel?> fetchHighlightStories(String highlightId) async {
    try {
      _log(
        '[HighlightController] fetchHighlightStories called with ID: '
        '$highlightId',
      );

      // Validate highlightId before API call
      if (highlightId.isEmpty) {
        _log('[HighlightController] empty highlightId provided');
        return null;
      }

      final response = await _service.fetchHighlightStories(highlightId);

      if (response.success) {
        _log(
          '[HighlightController] API success - stories count: '
          '${response.data.stories.length}',
        );
        return response.data;
      } else {
        _log('[HighlightController] API failed: ${response.message}');
        return null;
      }
    } catch (e) {
      _log('[HighlightController] error: $e');
      return null;
    }
  }
}
