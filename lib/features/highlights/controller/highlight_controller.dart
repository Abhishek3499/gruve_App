import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/highlights/api/highlight_service.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';

class HighlightController extends ChangeNotifier {
  HighlightController({
    HighlightService? service,
    HighlightStateManager? stateManager,
  }) : _service = service ?? HighlightService(),
       _stateManager = stateManager;

  final HighlightService _service;
  HighlightStateManager? _stateManager;

  bool isLoading = false;
  String message = '';
  bool isSuccess = false;

  List<HighlightModel> highlights = <HighlightModel>[];
  int totalCount = 0;

  void attachStateManager(HighlightStateManager stateManager) {
    _stateManager = stateManager;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<void> reset() async {
    message = '';
    isSuccess = false;
    highlights = <HighlightModel>[];
    totalCount = 0;
    await _stateManager?.clearAllHighlightedStories();
    notifyListeners();
  }

  Future<void> fetchMyHighlights() async {
    try {
      _log('[HighlightController] fetchMyHighlights start');

      isLoading = true;
      isSuccess = false;
      message = '';
      notifyListeners();

      final response = await _service.fetchMyHighlights();

      _log('[HighlightController] API success: ${response.success}');
      _log(
        '[HighlightController] Highlights total: '
        '${response.data.highlights.length}',
      );

      message = response.success
          ? 'Highlights fetched successfully'
          : 'Failed to fetch highlights';
      isSuccess = response.success;

      if (response.success) {
        highlights = List<HighlightModel>.unmodifiable(
          response.data.highlights,
        );
        totalCount = response.data.highlights.length;

        for (final highlight in highlights) {
          _log(
            '[HighlightController] Highlight: ${highlight.title}, '
            'stories=${highlight.stories.map((story) => story.id).toList()}',
          );
        }
      }
    } catch (e) {
      _log('[HighlightController] error: $e');
      message = 'Something went wrong';
      isSuccess = false;
    } finally {
      isLoading = false;
      notifyListeners();
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
