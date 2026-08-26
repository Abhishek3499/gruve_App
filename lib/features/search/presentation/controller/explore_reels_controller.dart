import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/search/data/datasource/explore_reels_service.dart';
import 'package:gruve_app/features/search/domain/entities/explore_reel_model.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';

class ExploreReelsController extends ChangeNotifier {
  ExploreReelsController({ExploreReelsService? service})
    : _service = service ?? ExploreReelsService() {
    _service.onPostsHydrated = _onPostsHydrated;
  }

  final ExploreReelsService _service;
  bool _disposed = false;

  ExploreReelsService get service => _service;

  Post displayPost(ExploreReel reel) => _service.displayPostFor(reel);

  void _onPostsHydrated() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _service.onPostsHydrated = null;
    super.dispose();
  }

  final List<ExploreReel> _reels = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  String _sort = 'trending';
  int _totalCount = 0;
  int _loadGeneration = 0;
  String? _lastLoadMoreKey;

  List<ExploreReel> get reels => List.unmodifiable(_reels);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get sort => _sort;
  int get totalCount => _totalCount;
  bool get isEmpty => _reels.isEmpty && !_isLoading && _error == null;

  Future<void> loadInitial({bool refresh = false}) async {
    if (_isLoading) return;

    AppLogger.d(
      '📡 [ExploreReelsController] loadInitial trigger=${refresh ? 'refresh' : 'initial'} '
      'page=1 sort=$_sort',
    );

    final generation = ++_loadGeneration;
    _lastLoadMoreKey = null;
    _isLoading = true;
    _error = null;
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    notifyListeners();

    try {
      final page = await _service.fetchReels(page: 1, sort: _sort);
      if (generation != _loadGeneration) return;

      _reels
        ..clear()
        ..addAll(page.results);
      _totalCount = page.count;
      _hasMore = page.hasMore;
      _page = page.nextPage ?? (page.hasMore ? 2 : 1);
      _error = null;
      ExploreReel.logAllUrls(page.results, prefix: 'initial/$_sort');
      _logDisplayPostUrls(page.results, prefix: 'initial/$_sort');
      _service.prefetchReels(_reels);
    } catch (e) {
      if (generation != _loadGeneration) return;
      AppLogger.d('❌ [ExploreReelsController] loadInitial: $e');
      _error = 'Failed to load explore reels';
      if (refresh) _reels.clear();
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore({String reason = 'scroll'}) async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    final requestKey = 'page=$_page|sort=$_sort';
    if (_lastLoadMoreKey == requestKey) {
      AppLogger.d(
        '⏸️ [ExploreReelsController] loadMore skipped duplicate params '
        'reason=$reason $requestKey',
      );
      return;
    }
    _lastLoadMoreKey = requestKey;

    AppLogger.d(
      '📡 [ExploreReelsController] loadMore trigger=$reason $requestKey',
    );

    final generation = _loadGeneration;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _service.fetchReels(page: _page, sort: _sort);
      if (generation != _loadGeneration) return;

      final existingIds = _reels.map((reel) => reel.id).toSet();
      final unique = page.results.where((reel) => !existingIds.contains(reel.id));
      final uniqueList = unique.toList();
      _reels.addAll(uniqueList);
      _hasMore = page.hasMore;
      _page = page.nextPage ?? (_page + 1);
      _totalCount = page.count;
      _lastLoadMoreKey = null;
      ExploreReel.logAllUrls(uniqueList, prefix: 'loadMore/$_sort');
      _logDisplayPostUrls(uniqueList, prefix: 'loadMore/$_sort');
      _service.prefetchReels(uniqueList);
    } catch (e) {
      if (generation != _loadGeneration) return;
      _lastLoadMoreKey = null;
      AppLogger.d('❌ [ExploreReelsController] loadMore: $e');
    } finally {
      if (generation == _loadGeneration) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> changeSort(String sort) async {
    final normalized = sort == 'latest' ? 'latest' : 'trending';
    if (_sort == normalized) return;

    _sort = normalized;
    _page = 1;
    _hasMore = true;
    _lastLoadMoreKey = null;
    _reels.clear();
    await loadInitial(refresh: true);
  }

  Future<void> refresh() => loadInitial(refresh: true);

  void _logDisplayPostUrls(Iterable<ExploreReel> reels, {required String prefix}) {
    for (final reel in reels) {
      final post = _service.displayPostFor(reel);
      AppLogger.d(
        '[displayPost/$prefix] id=${reel.id} '
        'media=${post.media.isEmpty ? '(empty)' : post.media} | '
        'thumb=${post.thumbnailUrl.isEmpty ? '(empty)' : post.thumbnailUrl} | '
        'grid=${post.gridPreviewUrl.isEmpty ? '(empty)' : post.gridPreviewUrl}',
        tag: 'ExploreReel',
      );
    }
  }
}
