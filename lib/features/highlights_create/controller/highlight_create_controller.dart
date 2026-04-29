import 'package:get/get.dart';
import 'package:gruve_app/features/highlights_create/api/highlight_create_service.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';

class HighlightCreateController extends GetxController {
  final HighlightCreateService _service = HighlightCreateService();
  final HighlightController _highlightController = Get.find<HighlightController>();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxString message = ''.obs;
  final RxBool isSuccess = false.obs;
  
  // Prevent multiple API calls
  bool isSubmitting = false;

  @override
  void onInit() {
    super.onInit();
    print("📱 [Highlight] Controller initialized");
  }

  void reset() {
    print("🔄 [Highlight] Resetting controller state");
    message.value = '';
    isSuccess.value = false;
    isLoading.value = false;
    isSubmitting = false;
  }

  /// Add story to highlight (create new or update existing)
  Future<void> addStoryToHighlight({
    String? highlightId,
    required String storyId,
    String? title,
  }) async {
    // Prevent multiple API calls
    if (isSubmitting) {
      print("⚠️ API already in progress, skipping duplicate call");
      return;
    }

    print("📱 [Highlight] User triggered action");
    print("🚀 [Highlight] API CALL START");
    
    try {
      // Validate required parameters
      if (storyId.isEmpty) {
        print("❌ [Highlight] Story ID cannot be empty");
        message.value = 'Story ID is required';
        isSuccess.value = false;
        print("🏁 [Highlight] API CALL END");
        return;
      }

      // For create operation, title is required
      if (highlightId == null || highlightId.isEmpty) {
        if (title == null || title.isEmpty) {
          print("❌ [Highlight] Title is required for creating new highlight");
          message.value = 'Title is required for creating new highlight';
          isSuccess.value = false;
          print("🏁 [Highlight] API CALL END");
          return;
        }
      }

      // Set submitting flag
      isSubmitting = true;
      isLoading.value = true;
      isSuccess.value = false;
      message.value = '';

      final isUpdate = highlightId != null && highlightId.isNotEmpty;
      
      if (isUpdate) {
        print("🔄 [Highlight] Updating existing highlight");
      } else {
        print("🆕 [Highlight] Creating new highlight");
      }

      print("📤 [Highlight] Sending Data:");
      print("   highlightId: $highlightId");
      print("   storyId: $storyId");
      print("   title: $title");

      final response = await _service.createOrUpdateHighlight(
        highlightId: highlightId,
        title: title ?? '',
        storyIds: [storyId],
      );

      if (response.success) {
        print("✅ [Highlight] Success");
        print("   highlightId: ${response.data.id}");
        print("   title: ${response.data.title}");
        print("   storiesCount: ${response.data.storiesCount}");

        message.value = isUpdate 
            ? 'Story added to highlight successfully! 🎉'
            : 'New highlight created successfully! 🎉';
        isSuccess.value = true;

        // Refresh highlights list
        print("🔄 [Highlight] Refreshing highlights list");
        await _highlightController.fetchMyHighlights();
      } else {
        print("❌ [Highlight] Failed - API returned false");
        message.value = 'Operation failed';
        isSuccess.value = false;
      }

    } catch (e) {
      print("❌ [Highlight] Failed with exception");
      print("   Error: $e");

      message.value = 'Something went wrong 😓';
      isSuccess.value = false;
    } finally {
      // Reset submitting flag
      isSubmitting = false;
      isLoading.value = false;
      print("🏁 [Highlight] API CALL END");
    }
  }
}
