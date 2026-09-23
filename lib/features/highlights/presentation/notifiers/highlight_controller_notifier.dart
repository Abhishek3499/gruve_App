import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';
import 'package:gruve_app/features/highlights/data/datasource/highlight_service.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_state_notifier.dart';

/// Immutable state for [HighlightControllerNotifier].
@immutable
class HighlightControllerState {
  final List<HighlightModel> highlights;
  final int totalCount;
  final bool isLoading;
  final String message;
  final bool isSuccess;

  const HighlightControllerState({
    this.highlights = const <HighlightModel>[],
    this.totalCount = 0,
    this.isLoading = false,
    this.message = '',
    this.isSuccess = false,
  });

  HighlightControllerState copyWith({
    List<HighlightModel>? highlights,
    int? totalCount,
    bool? isLoading,
    String? message,
    bool? isSuccess,
  }) {
    return HighlightControllerState(
      highlights: highlights ?? this.highlights,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighlightControllerState &&
        listEquals(other.highlights, highlights) &&
        other.totalCount == totalCount &&
        other.isLoading == isLoading &&
        other.message == message &&
        other.isSuccess == isSuccess;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(highlights),
    totalCount,
    isLoading,
    message,
    isSuccess,
  );
}

/// Riverpod Notifier replacing the legacy [HighlightController] ChangeNotifier.
class HighlightControllerNotifier extends Notifier<HighlightControllerState> {
  HighlightControllerNotifier({HighlightService? service})
    : _service = service ?? HighlightService();

  final HighlightService _service;
  CancelToken? _cancelToken;
  final Map<String, HighlightModel> _highlightStoriesCache = {};

  @override
  HighlightControllerState build() {
    ref.onDispose(() {
      cancelActiveRequests();
    });
    return const HighlightControllerState();
  }

  // Getters for convenience / backwards compatibility
  List<HighlightModel> get highlights => state.highlights;
  int get totalCount => state.totalCount;
  bool get isLoading => state.isLoading;
  String get message => state.message;
  bool get isSuccess => state.isSuccess;

  void cacheHighlightStories(HighlightModel highlight) {
    if (highlight.id.isEmpty || highlight.stories.isEmpty) return;
    _highlightStoriesCache[highlight.id] = highlight;
  }

  HighlightModel? cachedHighlightStories(String highlightId) {
    return _highlightStoriesCache[highlightId];
  }

  void invalidateHighlightStories(String highlightId) {
    _highlightStoriesCache.remove(highlightId);
  }

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Highlights view disposed');
    _cancelToken = null;
  }

  void _log(String message) {
    AppLogger.d(message);
  }

  Future<void> reset() async {
    _highlightStoriesCache.clear();
    state = const HighlightControllerState();
    await ref
        .read(highlightStateNotifierProvider.notifier)
        .clearAllHighlightedStories();
  }

  Future<void> fetchMyHighlights() async {
    try {
      _log('[HighlightControllerNotifier] fetchMyHighlights start');

      state = state.copyWith(isLoading: true, isSuccess: false, message: '');

      final response = await _service.fetchMyHighlights(
        cancelToken: _getCancelToken(),
      );

      _log('[HighlightControllerNotifier] API success: ${response.success}');
      _log(
        '[HighlightControllerNotifier] Highlights total: '
        '${response.data.highlights.length}',
      );

      final msg = response.success
          ? 'Highlights fetched successfully'
          : 'Failed to fetch highlights';
      final success = response.success;

      if (response.success) {
        final newHighlights = List<HighlightModel>.unmodifiable(
          response.data.highlights,
        );
        final count = response.data.highlights.length;

        for (final highlight in newHighlights) {
          _log(
            '[HighlightControllerNotifier] Highlight: ${highlight.title}, '
            'stories=${highlight.stories.map((story) => story.id).toList()}',
          );
        }

        state = state.copyWith(
          highlights: newHighlights,
          totalCount: count,
          message: msg,
          isSuccess: success,
        );
      } else {
        state = state.copyWith(message: msg, isSuccess: success);
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d(
          '[HighlightControllerNotifier] fetchMyHighlights cancelled',
        );
        return;
      }
      _log('[HighlightControllerNotifier] error: $e');
      state = state.copyWith(message: 'Something went wrong', isSuccess: false);
    } finally {
      state = state.copyWith(isLoading: false);
      _log('[HighlightControllerNotifier] fetchMyHighlights end');
    }
  }

  Future<HighlightModel?> fetchHighlightStories(
    String highlightId, {
    bool force = false,
  }) async {
    try {
      _log(
        '[HighlightControllerNotifier] fetchHighlightStories called with ID: '
        '$highlightId, force: $force',
      );

      if (highlightId.isEmpty) {
        _log('[HighlightControllerNotifier] empty highlightId provided');
        return null;
      }

      if (!force) {
        final cached = _highlightStoriesCache[highlightId];
        if (cached != null && cached.stories.isNotEmpty) {
          _log(
            '[HighlightControllerNotifier] Returning cached highlight stories',
          );
          return cached;
        }
      }

      final response = await _service.fetchHighlightStories(
        highlightId,
        cancelToken: _getCancelToken(),
      );

      if (response.success) {
        _log(
          '[HighlightControllerNotifier] API success - stories count: '
          '${response.data.stories.length}',
        );
        cacheHighlightStories(response.data);
        return response.data;
      } else {
        _log('[HighlightControllerNotifier] API failed: ${response.message}');
        return null;
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d(
          '[HighlightControllerNotifier] fetchHighlightStories cancelled',
        );
        return null;
      }
      _log('[HighlightControllerNotifier] error: $e');
      return null;
    }
  }

  Future<bool> deleteHighlight(String highlightId) async {
    try {
      _log('[HighlightControllerNotifier] deleteHighlight start: $highlightId');
      state = state.copyWith(isLoading: true, isSuccess: false, message: '');

      // Invalidate memory and HTTP caches
      invalidateHighlightStories(highlightId);
      await CacheInvalidationService().onHighlightUpdated(highlightId);

      // Simulated local deletion delay
      await Future.delayed(const Duration(milliseconds: 600));

      final updated = state.highlights
          .where((h) => h.id != highlightId)
          .toList();

      _log(
        '[HighlightControllerNotifier] deleteHighlight simulated local success',
      );
      state = state.copyWith(
        highlights: List<HighlightModel>.unmodifiable(updated),
        totalCount: updated.length,
        isSuccess: true,
        message: 'Highlight deleted successfully',
      );
      return true;
    } catch (e) {
      _log('[HighlightControllerNotifier] delete error: $e');
      state = state.copyWith(
        message: 'Failed to delete highlight',
        isSuccess: false,
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

/// App-scoped provider for [HighlightControllerNotifier].
final highlightControllerProvider =
    NotifierProvider<HighlightControllerNotifier, HighlightControllerState>(
      HighlightControllerNotifier.new,
    );
