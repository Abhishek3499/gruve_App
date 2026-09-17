import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/navigation/app_navigator.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';

/// Immutable state for [PostLikeNotifier] — per-post like overrides layered
/// on top of whatever [Post] the caller passes in, plus which post IDs
/// currently have an in-flight like/unlike request.
@immutable
class PostLikeState {
  const PostLikeState({this.overrides = const {}, this.inFlight = const {}});

  final Map<String, Post> overrides;
  final Set<String> inFlight;

  bool isLiked(Post post) => overrides[post.id]?.isLiked ?? post.isLiked;

  int likesCount(Post post) =>
      overrides[post.id]?.likesCount ?? post.likesCount;

  Post getPost(Post post) => overrides[post.id] ?? post;

  PostLikeState copyWith({
    Map<String, Post>? overrides,
    Set<String>? inFlight,
  }) {
    return PostLikeState(
      overrides: overrides ?? this.overrides,
      inFlight: inFlight ?? this.inFlight,
    );
  }
}

/// Replaces the previous `PostLikeProvider` (ChangeNotifier). Owns optimistic
/// like/unlike state for feed posts, keyed by post ID.
class PostLikeNotifier extends Notifier<PostLikeState> {
  final PostService _postService = PostService();

  @override
  PostLikeState build() => const PostLikeState();

  bool isLiked(Post post) => state.isLiked(post);

  int likesCount(Post post) => state.likesCount(post);

  Post getPost(Post post) => state.getPost(post);

  Future<void> toggleLike(Post post) async {
    final postId = post.id;
    if (postId.isEmpty || state.inFlight.contains(postId)) return;

    final currentLiked = state.isLiked(post);
    final currentCount = state.likesCount(post);

    final nextLiked = !currentLiked;
    final nextCount = nextLiked ? currentCount + 1 : currentCount - 1;

    state = state.copyWith(
      overrides: {
        ...state.overrides,
        postId: post.copyWith(isLiked: nextLiked, likesCount: nextCount),
      },
      inFlight: {...state.inFlight, postId},
    );

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
        unawaited(
          ProfileCountRefreshBridge.notifyCountsChanged(
            reason: 'post_like_toggled',
          ),
        );
      } else {
        _rollbackLike(postId, post, currentLiked, currentCount);
        _showErrorSnackBar();
      }
    } catch (e) {
      AppLogger.d('❌ [PostLikeNotifier] error toggling like: $e');
      _rollbackLike(postId, post, currentLiked, currentCount);
      _showErrorSnackBar();
    } finally {
      state = state.copyWith(inFlight: {...state.inFlight}..remove(postId));
    }
  }

  void _rollbackLike(String postId, Post originalPost, bool liked, int count) {
    state = state.copyWith(
      overrides: {
        ...state.overrides,
        postId: originalPost.copyWith(isLiked: liked, likesCount: count),
      },
    );
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
    AppLogger.d('🔄 [PostLikeNotifier] Resetting like data...');
    state = const PostLikeState();
    AppLogger.d('✅ [PostLikeNotifier] Like data reset complete');
  }
}

final postLikeNotifierProvider =
    NotifierProvider<PostLikeNotifier, PostLikeState>(PostLikeNotifier.new);
