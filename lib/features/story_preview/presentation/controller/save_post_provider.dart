import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class SavePostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  final Map<String, bool> _savedPosts = {};
  final Set<String> _loadingPosts = {};
  final Map<String, bool> _stableSavedPosts = {};
  final Map<String, Timer> _debounceTimers = {};
  
  List<Post> _savedPostsList = [];
  bool _isLoadingSavedPosts = false;
  String? _savedPostsError;
  Future<void>? _savedPostsFetchInFlight;
  DateTime? _lastSavedFetch;
  static const _savedPostsCacheTtl = Duration(minutes: 3);

  bool isSaved(String postId) => _savedPosts[postId] ?? false;
  bool isLoading(String postId) => _loadingPosts.contains(postId);
  
  List<Post> get savedPosts => _savedPostsList;
  List<Post> get savedPostsList => _savedPostsList;
  bool get isLoadingSavedPosts => _isLoadingSavedPosts;
  String? get savedPostsError => _savedPostsError;

  bool get isSavedPostsStale {
    if (_lastSavedFetch == null) return true;
    return DateTime.now().difference(_lastSavedFetch!) >= _savedPostsCacheTtl;
  }

  void initializeSavedState(String postId, bool isSaved) {
    _savedPosts[postId] = isSaved;
  }

  Future<void> toggleSavePost(String postId) async {
    AppLogger.d('🔄 [SavePostProvider] TOGGLE START postId=$postId');

    final previousState = _savedPosts[postId] ?? false;
    final targetState = !previousState;

    if (!_stableSavedPosts.containsKey(postId)) {
      _stableSavedPosts[postId] = previousState;
    }

    _savedPosts[postId] = targetState;
    notifyListeners();

    _debounceTimers[postId]?.cancel();

    _debounceTimers[postId] = Timer(const Duration(milliseconds: 300), () async {
      _debounceTimers.remove(postId);
      
      final stableState = _stableSavedPosts.remove(postId);
      final finalClientState = _savedPosts[postId] ?? false;

      if (stableState != null && finalClientState != stableState) {
        _loadingPosts.add(postId);
        notifyListeners();

        try {
          final result = await _postService.toggleSavePost(postId);
          final serverState = result['is_saved'] as bool;
          
          AppLogger.d('✅ [SavePostProvider] SERVER STATE: $serverState');
          _savedPosts[postId] = serverState;
          
          if (!serverState) {
            _savedPostsList.removeWhere((post) => post.id == postId);
            AppLogger.d('🗑️ [SavePostProvider] Removed from saved list postId=$postId');
          }
        } catch (e) {
          AppLogger.d('❌ [SavePostProvider] ERROR: $e');
          _savedPosts[postId] = stableState;

          // 🚨 Show SnackBar on failed optimistic update using global ScaffoldMessenger state
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Something went wrong'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } finally {
          _loadingPosts.remove(postId);
          notifyListeners();
        }
      } else {
        AppLogger.d('ℹ️ [SavePostProvider] Taps cancelled out. No API request sent.');
      }
    });
  }

  Future<void> fetchSavedPosts({bool forceRefresh = false}) async {
    if (!forceRefresh && !isSavedPostsStale) {
      AppLogger.d('✅ [SavePostProvider] Using cached saved posts');
      return;
    }

    if (_savedPostsFetchInFlight != null) {
      AppLogger.d('⏳ [SavePostProvider] Joining in-flight saved posts fetch');
      return _savedPostsFetchInFlight!;
    }

    final future = _runFetchSavedPosts();
    _savedPostsFetchInFlight = future;
    try {
      return await future;
    } finally {
      _savedPostsFetchInFlight = null;
    }
  }

  Future<void> _runFetchSavedPosts() async {
    AppLogger.d('🔄 [SavePostProvider] FETCH SAVED POSTS START');
    
    _isLoadingSavedPosts = true;
    _savedPostsError = null;
    notifyListeners();

    try {
      final posts = await _postService.fetchSavedPosts();
      
      _savedPostsList = posts;
      _lastSavedFetch = DateTime.now();
      
      // Update saved state map
      for (final post in posts) {
        _savedPosts[post.id] = true;
      }
      
      AppLogger.d('✅ [SavePostProvider] DATA LOADED: ${posts.length} posts');
    } catch (e) {
      AppLogger.d('❌ [SavePostProvider] FETCH ERROR: $e');
      _savedPostsError = 'Failed to load saved posts';
    } finally {
      _isLoadingSavedPosts = false;
      notifyListeners();
    }
  }

  /// Reset all save post data on logout
  void reset() {
    AppLogger.d('🔄 [SavePostProvider] Resetting save post data...');
    _stableSavedPosts.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _savedPosts.clear();
    _loadingPosts.clear();
    _savedPostsList.clear();
    _savedPostsError = null;
    _isLoadingSavedPosts = false;
    _savedPostsFetchInFlight = null;
    _lastSavedFetch = null;
    notifyListeners();
    AppLogger.d('✅ [SavePostProvider] Save post data reset complete');
  }

  void clearSavedState() {
    _stableSavedPosts.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _savedPosts.clear();
    _loadingPosts.clear();
    _savedPostsList.clear();
    _savedPostsError = null;
    _savedPostsFetchInFlight = null;
    _lastSavedFetch = null;
    notifyListeners();
  }
}
