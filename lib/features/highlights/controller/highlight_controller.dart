import 'package:get/get.dart';
import 'package:gruve_app/features/highlights/api/highlight_service.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';

class HighlightController extends GetxController {
  final HighlightService _service = HighlightService();

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxString message = ''.obs;
  final RxBool isSuccess = false.obs;

  // Highlights data
  final RxList<HighlightModel> highlights = <HighlightModel>[].obs;
  final RxInt totalCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
  }

  void reset() {
    message.value = '';
    isSuccess.value = false;
    highlights.clear();
    totalCount.value = 0;
  }

  Future<void> fetchMyHighlights() async {
    try {
      print("🚀 [Controller] fetchMyHighlights START");

      isLoading.value = true;
      isSuccess.value = false;
      message.value = '';

      final response = await _service.fetchMyHighlights();

      print("🔥 [Controller] API SUCCESS: ${response.success}");
      print("🔥 [Controller] TOTAL: ${response.data.highlights.length}");

      message.value = response.success
          ? 'Highlights fetched successfully'
          : 'Failed to fetch highlights';

      isSuccess.value = response.success;

      if (response.success) {
        highlights.clear();
        highlights.addAll(response.data.highlights);
        totalCount.value = response.data.highlights.length;
      }
    } catch (e) {
      print("❌ [Controller] ERROR: $e");

      message.value = 'Something went wrong 😓';
      isSuccess.value = false;
    } finally {
      isLoading.value = false;
      print("🏁 [Controller] fetchMyHighlights END");
    }
  }
}
