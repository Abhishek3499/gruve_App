import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';

/// Immutable state for [PostViewNotifier] — post IDs whose view has already
/// been recorded (or is in flight) this session, so re-entering the
/// viewport never re-fires the view API for the same post.
@immutable
class PostViewState {
  const PostViewState({this.viewedPostIds = const {}});

  final Set<String> viewedPostIds;

  bool isViewed(String postId) => viewedPostIds.contains(postId);

  PostViewState copyWith({Set<String>? viewedPostIds}) {
    return PostViewState(viewedPostIds: viewedPostIds ?? this.viewedPostIds);
  }
}

class PostViewNotifier extends Notifier<PostViewState> {
  final PostService _postService = PostService();

  @override
  PostViewState build() => const PostViewState();

  bool isViewed(String postId) => state.isViewed(postId);

  /// Fires the view API once per [postId] per session. Marks the post as
  /// viewed optimistically before the request completes so rapid
  /// visibility toggling (scroll jitter) can't send it twice.
  void recordView(String postId) {
    if (postId.isEmpty || state.isViewed(postId)) return;

    state = state.copyWith(viewedPostIds: {...state.viewedPostIds, postId});

    unawaited(_postService.recordPostView(postId));
  }

  void reset() {
    state = const PostViewState();
  }
}

final postViewNotifierProvider =
    NotifierProvider<PostViewNotifier, PostViewState>(PostViewNotifier.new);
