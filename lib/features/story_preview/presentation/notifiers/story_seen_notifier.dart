import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state for [StorySeenNotifier] — user IDs whose stories have
/// been watched in this session, used to optimistically clear the feed
/// ring's "unseen" state before the next feed refresh confirms it.
@immutable
class StorySeenState {
  const StorySeenState({this.seenUserIds = const {}});

  final Set<String> seenUserIds;

  bool isSeen(String userId) => seenUserIds.contains(userId);

  StorySeenState copyWith({Set<String>? seenUserIds}) {
    return StorySeenState(seenUserIds: seenUserIds ?? this.seenUserIds);
  }
}

class StorySeenNotifier extends Notifier<StorySeenState> {
  @override
  StorySeenState build() => const StorySeenState();

  bool isSeen(String userId) => state.isSeen(userId);

  /// Marks [userId]'s story as seen — the feed ring drops from unseen
  /// (colorful) to seen (gray) without waiting for a full feed reload.
  void markUserSeen(String userId) {
    if (userId.isEmpty || state.seenUserIds.contains(userId)) return;
    state = state.copyWith(seenUserIds: {...state.seenUserIds, userId});
  }

  void reset() {
    state = const StorySeenState();
  }
}

final storySeenNotifierProvider =
    NotifierProvider<StorySeenNotifier, StorySeenState>(StorySeenNotifier.new);
