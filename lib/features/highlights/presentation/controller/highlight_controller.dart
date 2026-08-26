import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/highlights/data/datasource/highlight_service.dart';
import 'package:gruve_app/features/highlights/presentation/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
  CancelToken? _cancelToken;
  final Map<String, HighlightModel> _highlightStoriesCache = {};

  void cacheHighlightStories(HighlightModel highlight) {
    if (highlight.id.isEmpty || highlight.stories.isEmpty) return;
    _highlightStoriesCache[highlight.id] = highlight;
  }

  HighlightModel? cachedHighlightStories(String highlightId) {
    return _highlightStoriesCache[highlightId];
  }

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Highlights view disposed');
    _cancelToken = null;
  }

  void attachStateManager(HighlightStateManager stateManager) {
    _stateManager = stateManager;
  }

  void _log(String message) {
    AppLogger.d(message);
    
  }

  Future<void> reset() async {
    message = '';
    isSuccess = false;
    highlights = <HighlightModel>[];
    totalCount = 0;
    _highlightStoriesCache.clear();
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

      final response = await _service.fetchMyHighlights(cancelToken: _getCancelToken());

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
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('[HighlightController] fetchMyHighlights cancelled');
        return;
      }
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

      if (highlightId.isEmpty) {
        _log('[HighlightController] empty highlightId provided');
        return null;
      }

      final cached = _highlightStoriesCache[highlightId];
      if (cached != null && cached.stories.isNotEmpty) {
        _log('[HighlightController] Returning cached highlight stories');
        return cached;
      }

      final response = await _service.fetchHighlightStories(
        highlightId,
        cancelToken: _getCancelToken(),
      );

      if (response.success) {
        _log(
          '[HighlightController] API success - stories count: '
          '${response.data.stories.length}',
        );
        cacheHighlightStories(response.data);
        return response.data;
      } else {
        _log('[HighlightController] API failed: ${response.message}');
        return null;
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('[HighlightController] fetchHighlightStories cancelled');
        return null;
      }
      _log('[HighlightController] error: $e');
      return null;
    }
  }

  Future<bool> deleteHighlight(String highlightId) async {
    try {
      _log('[HighlightController] deleteHighlight start: $highlightId');
      isLoading = true;
      isSuccess = false;
      message = '';
      notifyListeners();

      // Simulated local deletion delay
      await Future.delayed(const Duration(milliseconds: 600));

      final updated = highlights.where((h) => h.id != highlightId).toList();
      highlights = List<HighlightModel>.unmodifiable(updated);
      totalCount = highlights.length;

      _log('[HighlightController] deleteHighlight simulated local success');
      isSuccess = true;
      message = 'Highlight deleted successfully';
      return true;
    } catch (e) {
      _log('[HighlightController] delete error: $e');
      message = 'Failed to delete highlight';
      isSuccess = false;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  @override
  void dispose() {
    cancelActiveRequests();
    super.dispose();
  }
}
