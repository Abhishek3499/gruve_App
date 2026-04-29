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
      print('[HighlightController] fetchMyHighlights START');

      isLoading.value = true;
      isSuccess.value = false;
      message.value = '';

      final response = await _service.fetchMyHighlights();

      print('[HighlightController] API success: ${response.success}');
      print(
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
          print(
            '[HighlightController] Highlight: ${highlight.title}, '
            'stories=${highlight.stories.map((story) => story.id).toList()}',
          );
        }

        HighlightStateManager.ensureRegistered();
      }
    } catch (e) {
      print('[HighlightController] ERROR: $e');
      message.value = 'Something went wrong';
      isSuccess.value = false;
    } finally {
      isLoading.value = false;
      print('[HighlightController] fetchMyHighlights END');
    }
  }

  Future<HighlightModel?> fetchHighlightStories(String highlightId) async {
    try {
      debugPrint('[Controller] fetchHighlightStories CALLED with ID: $highlightId');
      
      // Validate highlightId before API call
      if (highlightId.isEmpty) {
        debugPrint('[Controller] ERROR: Empty highlightId provided');
        return null;
      }
      
      final response = await _service.fetchHighlightStories(highlightId);
      
      if (response.success) {
        debugPrint('[Controller] API success - Stories count: ${response.data.stories.length}');
        return response.data;
      } else {
        debugPrint('[Controller] API failed: ${response.message}');
        return null;
      }
    } catch (e) {
      debugPrint('[Controller] ERROR: $e');
      return null;
    }
  }
}
