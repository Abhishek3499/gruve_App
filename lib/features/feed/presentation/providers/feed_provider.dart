import 'package:flutter/foundation.dart';
import 'package:gruve_app/features/feed/data/models/post_model.dart';
import 'package:gruve_app/features/feed/data/repositories/feed_repository.dart';
import 'package:gruve_app/core/loading/loading_state_manager.dart';

/// Provider for feed state management
/// Handles loading states, pagination, and post interactions
class FeedProvider extends ChangeNotifier {
  final FeedRepository _repository;
  
  FeedProvider(this._repository) {
    debugPrint('🏗️ [FeedProvider] Provider initialized');
  }

  // State management
  final LoadingStateManager<List<PostModel>> _stateManager = LoadingStateManager<List<PostModel>>();
  int _currentPage = 1;
  bool _hasMoreData = true;
  static const int _pageSize = 20;
  FeedType _currentType = FeedType.all;

  // Getters
  LoadState get loadState => _stateManager.state;
  List<PostModel> get posts => _stateManager.data ?? [];
  bool get isLoading => _stateManager.isLoading;
  bool get isRefreshing => _stateManager.isRefreshing;
  bool get isPaginating => _stateManager.isPaginating;
  bool get hasError => _stateManager.hasError;
  String? get error => _stateManager.error;
  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;
  FeedType get currentType => _currentType;

  /// Fetch initial feed
  Future<void> fetchFeed({FeedType? type}) async {
    if (type != null) {
      _currentType = type;
      _currentPage = 1;
      _hasMoreData = true;
    }

    _stateManager.setFirstLoad();
    debugPrint('📡 [FeedProvider] Fetching feed: type=$_currentType, page=$_currentPage');

    try {
      final response = await _repository.fetchFeed(
        page: _currentPage,
        limit: _pageSize,
        type: _currentType,
      );

      _stateManager.setIdle(response.posts);
      _hasMoreData = response.hasMore;
      
      debugPrint('✅ [FeedProvider] Feed loaded: ${response.posts.length} posts');
    } catch (e) {
      _stateManager.setError(e.toString());
      debugPrint('❌ [FeedProvider] Error loading feed: $e');
    }
  }

  /// Refresh feed
  Future<void> refreshFeed() async {
    _currentPage = 1;
    _hasMoreData = true;
    _stateManager.setRefreshing();
    
    debugPrint('🔄 [FeedProvider] Refreshing feed');

    try {
      final response = await _repository.fetchFeed(
        page: _currentPage,
        limit: _pageSize,
        type: _currentType,
      );

      _stateManager.setIdle(response.posts);
      _hasMoreData = response.hasMore;
      
      debugPrint('✅ [FeedProvider] Feed refreshed: ${response.posts.length} posts');
    } catch (e) {
      _stateManager.setError(e.toString());
      debugPrint('❌ [FeedProvider] Error refreshing feed: $e');
    }
  }

  /// Load more posts (pagination)
  Future<void> loadMorePosts() async {
    if (isLoading || !hasMoreData) {
      debugPrint('⏸️ [FeedProvider] Skipping load more - Loading: $isLoading, HasMore: $hasMoreData');
      return;
    }

    _currentPage++;
    _stateManager.setPaginating();
    
    debugPrint('⬇️ [FeedProvider] Loading more posts: page=$_currentPage');

    try {
      final response = await _repository.fetchFeed(
        page: _currentPage,
        limit: _pageSize,
        type: _currentType,
      );

      _stateManager.addData(response.posts);
      _hasMoreData = response.hasMore;
      
      debugPrint('✅ [FeedProvider] More posts loaded: ${response.posts.length} posts');
    } catch (e) {
      _currentPage--; // Revert page number on error
      _stateManager.setError(e.toString());
      debugPrint('❌ [FeedProvider] Error loading more posts: $e');
    }
  }

  /// Toggle like on a post
  Future<void> toggleLike(String postId) async {
    final postIndex = posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = posts[postIndex];
    final newIsLiked = !post.isLiked;
    final newLikesCount = newIsLiked ? post.likesCount + 1 : post.likesCount - 1;

    // Optimistic update
    final updatedPost = post.copyWith(
      isLiked: newIsLiked,
      likesCount: newLikesCount,
    );
    
    final updatedPosts = List<PostModel>.from(posts);
    updatedPosts[postIndex] = updatedPost;
    _stateManager.updateData(updatedPosts);

    debugPrint('🤍 [FeedProvider] Optimistic like update: postId=$postId, liked=$newIsLiked');

    // Sync with backend
    final success = await _repository.toggleLike(postId, newIsLiked);
    
    if (!success) {
      // Revert optimistic update on failure
      final revertedPosts = List<PostModel>.from(posts);
      revertedPosts[postIndex] = post;
      _stateManager.updateData(revertedPosts);
      debugPrint('❌ [FeedProvider] Like update failed, reverted: $postId');
    } else {
      debugPrint('✅ [FeedProvider] Like update successful: $postId');
    }
  }

  /// Toggle save on a post
  Future<void> toggleSave(String postId) async {
    final postIndex = posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = posts[postIndex];
    final newIsSaved = !post.isSaved;

    // Optimistic update
    final updatedPost = post.copyWith(isSaved: newIsSaved);
    
    final updatedPosts = List<PostModel>.from(posts);
    updatedPosts[postIndex] = updatedPost;
    _stateManager.updateData(updatedPosts);

    debugPrint('🔖 [FeedProvider] Optimistic save update: postId=$postId, saved=$newIsSaved');

    // Sync with backend
    final success = await _repository.toggleSave(postId, newIsSaved);
    
    if (!success) {
      // Revert optimistic update on failure
      final revertedPosts = List<PostModel>.from(posts);
      revertedPosts[postIndex] = post;
      _stateManager.updateData(revertedPosts);
      debugPrint('❌ [FeedProvider] Save update failed, reverted: $postId');
    } else {
      debugPrint('✅ [FeedProvider] Save update successful: $postId');
    }
  }

  /// Share a post
  Future<bool> sharePost(String postId) async {
    debugPrint('📤 [FeedProvider] Sharing post: $postId');
    
    final success = await _repository.sharePost(postId);
    
    if (success) {
      // Update share count optimistically
      final postIndex = posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = posts[postIndex];
        final updatedPost = post.copyWith(sharesCount: post.sharesCount + 1);
        
        final updatedPosts = List<PostModel>.from(posts);
        updatedPosts[postIndex] = updatedPost;
        _stateManager.updateData(updatedPosts);
      }
    }
    
    return success;
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    debugPrint('🗑️ [FeedProvider] Deleting post: $postId');
    
    final success = await _repository.deletePost(postId);
    
    if (success) {
      // Remove from list
      final updatedPosts = posts.where((post) => post.id != postId).toList();
      _stateManager.updateData(updatedPosts);
    }
    
    return success;
  }

  /// Report a post
  Future<bool> reportPost(String postId, String reason) async {
    debugPrint('🚨 [FeedProvider] Reporting post: $postId, reason: $reason');
    
    return await _repository.reportPost(postId, reason);
  }

  /// Change feed type
  void changeFeedType(FeedType type) {
    if (_currentType != type) {
      _currentType = type;
      fetchFeed(type: type);
      debugPrint('🔄 [FeedProvider] Feed type changed to: ${type.name}');
    }
  }

  /// Clear error state
  void clearError() {
    if (hasError) {
      _stateManager.setIdle(posts);
      debugPrint('✅ [FeedProvider] Error cleared');
    }
  }

  /// Reset provider state
  void reset() {
    _stateManager.reset();
    _currentPage = 1;
    _hasMoreData = true;
    _currentType = FeedType.all;
    debugPrint('🔄 [FeedProvider] Provider state reset');
  }

  @override
  void dispose() {
    _stateManager.reset();
    debugPrint('🗑️ [FeedProvider] Provider disposed');
    super.dispose();
  }
}
