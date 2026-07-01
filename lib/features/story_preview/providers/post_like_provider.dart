import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/profile/controller/profile_count_refresh_bridge.dart';
import '../api/create_post_api/model/post_model.dart';
import '../api/create_post_api/post_service.dart';

class PostLikeProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  final Map<String, bool> _likedPosts = {};
  final Map<String, int> _likesCount = {};
  final Set<String> _inFlight = {};

  bool isLiked(Post post) => _likedPosts[post.id] ?? post.isLiked;

  int likesCount(Post post) => _likesCount[post.id] ?? post.likesCount;

  Future<void> toggleLike(Post post) async {
    final postId = post.id;
    if (postId.isEmpty || _inFlight.contains(postId)) return;

    final currentLiked = isLiked(post);
    final currentCount = likesCount(post);

    final nextLiked = !currentLiked;
    final nextCount = nextLiked ? currentCount + 1 : currentCount - 1;

    _inFlight.add(postId);
    _likedPosts[postId] = nextLiked;
    _likesCount[postId] = nextCount;
    notifyListeners();

    if (nextLiked) {
      try {
        await HapticFeedback.vibrate();
      } catch (e) {
        AppLogger.d('⚠️ Haptic feedback error: $e');
      }
    }

    try {
      final success = await _postService.likePost(postId);
      if (success) {
        post.isLiked = nextLiked;
        post.likesCount = nextCount;

        unawaited(
          ProfileCountRefreshBridge.notifyCountsChanged(
            reason: 'post_like_toggled',
          ),
        );
      } else {
        _rollbackLike(postId, currentLiked, currentCount);
        _showErrorSnackBar();
      }
    } catch (e) {
      AppLogger.d('❌ [PostLikeProvider] error toggling like: $e');
      _rollbackLike(postId, currentLiked, currentCount);
      _showErrorSnackBar();
    } finally {
      _inFlight.remove(postId);
    }
  }

  void _rollbackLike(String postId, bool liked, int count) {
    _likedPosts[postId] = liked;
    _likesCount[postId] = count;
    notifyListeners();
  }

  void _showErrorSnackBar() {
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Could not update like. Please try again.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void reset() {
    AppLogger.d('🔄 [PostLikeProvider] Resetting like data...');
    _likedPosts.clear();
    _likesCount.clear();
    _inFlight.clear();
    notifyListeners();
    AppLogger.d('✅ [PostLikeProvider] Like data reset complete');
  }
}
