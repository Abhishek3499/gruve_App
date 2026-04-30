import 'package:flutter/foundation.dart';
import '../api/create_post_api/post_service.dart';
import '../api/create_post_api/model/post_model.dart';

class SavePostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  final Map<String, bool> _savedPosts = {};
  final Set<String> _loadingPosts = {};
  
  List<Post> _savedPostsList = [];
  bool _isLoadingSavedPosts = false;
  String? _savedPostsError;

  bool isSaved(String postId) => _savedPosts[postId] ?? false;
  bool isLoading(String postId) => _loadingPosts.contains(postId);
  
  List<Post> get savedPostsList => _savedPostsList;
  bool get isLoadingSavedPosts => _isLoadingSavedPosts;
  String? get savedPostsError => _savedPostsError;

  void initializeSavedState(String postId, bool isSaved) {
    _savedPosts[postId] = isSaved;
  }

  Future<void> toggleSavePost(String postId) async {
    if (_loadingPosts.contains(postId)) {
      debugPrint('🔄 [SavePostProvider] Already loading postId=$postId');
      return;
    }

    debugPrint('🔄 [SavePostProvider] TOGGLE START postId=$postId');
    
    _loadingPosts.add(postId);
    
    final previousState = _savedPosts[postId] ?? false;
    final optimisticState = !previousState;
    
    debugPrint('🔁 [SavePostProvider] OPTIMISTIC UPDATE: $previousState → $optimisticState');
    _savedPosts[postId] = optimisticState;
    notifyListeners();

    try {
      final result = await _postService.toggleSavePost(postId);
      final serverState = result['is_saved'] as bool;
      
      debugPrint('✅ [SavePostProvider] SERVER STATE: $serverState');
      _savedPosts[postId] = serverState;
      
      // If unsaved, remove from saved list
      if (!serverState) {
        _savedPostsList.removeWhere((post) => post.id == postId);
        debugPrint('🗑️ [SavePostProvider] Removed from saved list postId=$postId');
      }
      
      notifyListeners();
      
      debugPrint('✅ [SavePostProvider] STATE UPDATED postId=$postId isSaved=$serverState');
    } catch (e) {
      debugPrint('❌ [SavePostProvider] ERROR: $e');
      debugPrint('🔁 [SavePostProvider] ROLLBACK: $optimisticState → $previousState');
      
      _savedPosts[postId] = previousState;
      notifyListeners();
      
      rethrow;
    } finally {
      _loadingPosts.remove(postId);
      notifyListeners();
    }
  }

  Future<void> fetchSavedPosts() async {
    debugPrint('🔄 [SavePostProvider] FETCH SAVED POSTS START');
    
    _isLoadingSavedPosts = true;
    _savedPostsError = null;
    notifyListeners();

    try {
      final posts = await _postService.fetchSavedPosts();
      
      _savedPostsList = posts;
      
      // Update saved state map
      for (final post in posts) {
        _savedPosts[post.id] = true;
      }
      
      debugPrint('✅ [SavePostProvider] DATA LOADED: ${posts.length} posts');
    } catch (e) {
      debugPrint('❌ [SavePostProvider] FETCH ERROR: $e');
      _savedPostsError = 'Failed to load saved posts';
    } finally {
      _isLoadingSavedPosts = false;
      notifyListeners();
    }
  }

  void clearSavedState() {
    _savedPosts.clear();
    _loadingPosts.clear();
    _savedPostsList.clear();
    _savedPostsError = null;
    notifyListeners();
  }
}
