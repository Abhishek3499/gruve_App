import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/navigation/app_navigator.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Immutable state for [SavePostNotifier]: per-post saved/loading flags plus
/// the cached "Saved" tab data (list, loading flag, error).
@immutable
class SavePostState {
  const SavePostState({
    this.savedPosts = const {},
    this.loadingPosts = const {},
    this.savedPostsList = const [],
    this.isLoadingSavedPosts = false,
    this.savedPostsError,
  });

  final Map<String, bool> savedPosts;
  final Set<String> loadingPosts;
  final List<Post> savedPostsList;
  final bool isLoadingSavedPosts;
  final String? savedPostsError;

  bool isSaved(String postId) => savedPosts[postId] ?? false;
  bool isLoading(String postId) => loadingPosts.contains(postId);

  SavePostState copyWith({
    Map<String, bool>? savedPosts,
    Set<String>? loadingPosts,
    List<Post>? savedPostsList,
    bool? isLoadingSavedPosts,
    String? savedPostsError,
    bool clearError = false,
  }) {
    return SavePostState(
      savedPosts: savedPosts ?? this.savedPosts,
      loadingPosts: loadingPosts ?? this.loadingPosts,
      savedPostsList: savedPostsList ?? this.savedPostsList,
      isLoadingSavedPosts: isLoadingSavedPosts ?? this.isLoadingSavedPosts,
      savedPostsError: clearError
          ? null
          : (savedPostsError ?? this.savedPostsError),
    );
  }
}

class SavePostNotifier extends Notifier<SavePostState> {
  final PostService _postService = PostService();
  final Map<String, bool> _stableSavedPosts = {};
  final Map<String, Timer> _debounceTimers = {};

  Future<void>? _savedPostsFetchInFlight;
  DateTime? _lastSavedFetch;
  static const _savedPostsCacheTtl = Duration(minutes: 3);

  @override
  SavePostState build() => const SavePostState();

  bool isSaved(String postId) => state.isSaved(postId);
  bool isLoading(String postId) => state.isLoading(postId);

  List<Post> get savedPosts => state.savedPostsList;
  List<Post> get savedPostsList => state.savedPostsList;
  bool get isLoadingSavedPosts => state.isLoadingSavedPosts;
  String? get savedPostsError => state.savedPostsError;

  bool get isSavedPostsStale {
    if (_lastSavedFetch == null) return true;
    return DateTime.now().difference(_lastSavedFetch!) >= _savedPostsCacheTtl;
  }

  void initializeSavedState(String postId, bool isSaved) {
    state = state.copyWith(savedPosts: {...state.savedPosts, postId: isSaved});
  }

  Future<void> toggleSavePost(String postId) async {
    AppLogger.d('🔄 [SavePostNotifier] TOGGLE START postId=$postId');

    final previousState = state.isSaved(postId);
    final targetState = !previousState;

    if (!_stableSavedPosts.containsKey(postId)) {
      _stableSavedPosts[postId] = previousState;
    }

    state = state.copyWith(
      savedPosts: {...state.savedPosts, postId: targetState},
    );

    _debounceTimers[postId]?.cancel();

    _debounceTimers[postId] = Timer(const Duration(milliseconds: 300), () async {
      _debounceTimers.remove(postId);

      final stableState = _stableSavedPosts.remove(postId);
      final finalClientState = state.isSaved(postId);

      if (stableState != null && finalClientState != stableState) {
        state = state.copyWith(loadingPosts: {...state.loadingPosts, postId});

        try {
          final result = await _postService.toggleSavePost(postId);
          final serverState = result['is_saved'] as bool;

          AppLogger.d('✅ [SavePostNotifier] SERVER STATE: $serverState');

          var updatedList = state.savedPostsList;
          if (!serverState) {
            updatedList = state.savedPostsList
                .where((post) => post.id != postId)
                .toList();
            AppLogger.d(
              '🗑️ [SavePostNotifier] Removed from saved list postId=$postId',
            );
          }

          state = state.copyWith(
            savedPosts: {...state.savedPosts, postId: serverState},
            savedPostsList: updatedList,
          );
        } catch (e) {
          AppLogger.d('❌ [SavePostNotifier] ERROR: $e');
          state = state.copyWith(
            savedPosts: {...state.savedPosts, postId: stableState},
          );

          // 🚨 Show SnackBar on failed optimistic update using global ScaffoldMessenger state
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Something went wrong'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } finally {
          state = state.copyWith(
            loadingPosts: {...state.loadingPosts}..remove(postId),
          );
        }
      } else {
        AppLogger.d(
          'ℹ️ [SavePostNotifier] Taps cancelled out. No API request sent.',
        );
      }
    });
  }

  Future<void> fetchSavedPosts({bool forceRefresh = false}) async {
    if (!forceRefresh && !isSavedPostsStale) {
      AppLogger.d('✅ [SavePostNotifier] Using cached saved posts');
      return;
    }

    if (_savedPostsFetchInFlight != null) {
      AppLogger.d('⏳ [SavePostNotifier] Joining in-flight saved posts fetch');
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
    AppLogger.d('🔄 [SavePostNotifier] FETCH SAVED POSTS START');

    state = state.copyWith(isLoadingSavedPosts: true, clearError: true);

    try {
      final posts = await _postService.fetchSavedPosts();

      _lastSavedFetch = DateTime.now();

      final updatedSavedPosts = {...state.savedPosts};
      for (final post in posts) {
        updatedSavedPosts[post.id] = true;
      }

      state = state.copyWith(
        savedPostsList: posts,
        savedPosts: updatedSavedPosts,
      );

      AppLogger.d('✅ [SavePostNotifier] DATA LOADED: ${posts.length} posts');
    } catch (e) {
      AppLogger.d('❌ [SavePostNotifier] FETCH ERROR: $e');
      state = state.copyWith(savedPostsError: 'Failed to load saved posts');
    } finally {
      state = state.copyWith(isLoadingSavedPosts: false);
    }
  }

  /// Reset all save post data on logout
  void reset() {
    AppLogger.d('🔄 [SavePostNotifier] Resetting save post data...');
    _stableSavedPosts.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _savedPostsFetchInFlight = null;
    _lastSavedFetch = null;
    state = const SavePostState();
    AppLogger.d('✅ [SavePostNotifier] Save post data reset complete');
  }

  void clearSavedState() {
    _stableSavedPosts.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _savedPostsFetchInFlight = null;
    _lastSavedFetch = null;
    state = state.copyWith(
      savedPosts: const {},
      loadingPosts: const {},
      savedPostsList: const [],
      clearError: true,
    );
  }
}

final savePostNotifierProvider =
    NotifierProvider<SavePostNotifier, SavePostState>(SavePostNotifier.new);
