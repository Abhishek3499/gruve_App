import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/navigation/app_navigator.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';

import 'package:gruve_app/features/home/data/models/subscribe_model.dart';
import 'package:gruve_app/features/home/data/services/subscribe_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class SubscribeNotifier extends ChangeNotifier {
  static final SubscribeNotifier _instance = SubscribeNotifier._internal();
  factory SubscribeNotifier() => _instance;
  SubscribeNotifier._internal();

  final SubscribeService _subscribeService = SubscribeService();
  final Map<String, SubscribeModel> _users = {};
  final Map<String, bool> _serverStates = {};
  final Set<String> _syncingUsers = <String>{};
  final Set<String> _pendingResyncUsers = <String>{};

  Map<String, SubscribeModel> get users => Map.unmodifiable(_users);

  void _log(String message) {
    AppLogger.d('🎛️ [SubscribeNotifier] $message');
  }

  bool isUserSubscribed(String userId) {
    final localUser = _users[userId];
    if (localUser != null) return localUser.isSubscribed;
    return _subscribeService.isUserSubscribed(userId);
  }

  String getFollowStatus(String userId) {
    return _users[userId]?.followStatus ?? 'none';
  }

  bool isSubscriptionSynced(String userId) {
    final local = isUserSubscribed(userId);
    final server =
        _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);
    return server == local;
  }

  SubscribeModel? getUserSubscribeModel(String userId) {
    return _users[userId];
  }

  void addOrUpdateUser(SubscribeModel user) {
    final existing = _users[user.userId];
    final localStatus = existing?.isSubscribed;
    final resolvedStatus = localStatus == false
        ? false
        : user.isSubscribed
        ? true
        : localStatus == true;

    _users[user.userId] = user.copyWith(
      username: user.username.isNotEmpty
          ? user.username
          : (existing?.username ?? user.userId),
      isSubscribed: resolvedStatus,
      followStatus: user.followStatus,
      subscribedAt: resolvedStatus
          ? (existing?.subscribedAt ?? user.subscribedAt ?? DateTime.now())
          : null,
    );

    if (user.isSubscribed) {
      _serverStates[user.userId] = true;
    } else if (localStatus != true) {
      _serverStates[user.userId] = false;
    }
    _subscribeService.setSubscriptionStatus(user.userId, resolvedStatus);
    if (existing != null && existing.isSubscribed != resolvedStatus) {
      notifyListeners();
    }
  }

  void _applyLocalState(
    String userId,
    bool isSubscribed, {
    String? username,
    String followStatus = 'none',
    bool notify = true,
  }) {
    final existing = _users[userId];
    final resolvedUsername = (username != null && username.isNotEmpty)
        ? username
        : (existing?.username ?? userId);

    _users[userId] = SubscribeModel(
      userId: userId,
      username: resolvedUsername,
      isSubscribed: isSubscribed,
      followStatus: followStatus,
      subscribedAt: isSubscribed
          ? (existing?.subscribedAt ?? DateTime.now())
          : null,
    );
    _subscribeService.setSubscriptionStatus(userId, isSubscribed);

    if (notify) notifyListeners();
  }

  Future<void> _syncWithServer(String userId) async {
    if (_syncingUsers.contains(userId)) {
      _pendingResyncUsers.add(userId);
      return;
    }

    _syncingUsers.add(userId);
    var syncFailed = false;

    try {
      // Directly call the toggle API — no pre-fetch profile loop.
      // The toggle endpoint is the source of truth for follow_status.
      try {
        final result = await _subscribeService.toggleSubscription(userId);
        _serverStates[userId] = result.isFollowing;

        // Always apply server result — covers requested/following/none
        _applyLocalState(
          userId,
          result.isFollowing,
          followStatus: result.followStatus,
        );

        await ProfileCountRefreshBridge.notifyCountsChanged(
          reason: result.isFollowing ? 'user_subscribed' : 'user_unsubscribed',
        );
        unawaited(CacheInvalidationService().onUserFollowed(userId));
        unawaited(CacheManager().invalidatePattern(userId));
      } catch (e) {
        _log('❌ sync failed for userId=$userId error=$e');
        syncFailed = true;

        // Revert to last known server state
        final latestServerState =
            _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);
        _applyLocalState(userId, latestServerState);

        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _syncingUsers.remove(userId);
      final needsResync = _pendingResyncUsers.remove(userId);
      if (needsResync && !syncFailed) {
        unawaited(_syncWithServer(userId));
      }
    }
  }

  Future<bool> toggleSubscription(String userId) async {
    final currentStatus = isUserSubscribed(userId);
    // Optimistic: flip the bool, keep followStatus as-is until server confirms
    final optimisticStatus = !currentStatus;
    _applyLocalState(
      userId,
      optimisticStatus,
      followStatus: getFollowStatus(userId),
    );
    unawaited(_syncWithServer(userId));
    return optimisticStatus;
  }

  Future<bool> subscribeToUser(String userId) async {
    _applyLocalState(userId, true, followStatus: 'following');
    unawaited(_syncWithServer(userId));
    return true;
  }

  Future<bool> unsubscribeFromUser(String userId) async {
    _applyLocalState(userId, false, followStatus: 'none');
    unawaited(_syncWithServer(userId));
    return false;
  }

  Set<String> getSubscribedUsers() {
    return _subscribeService.getSubscribedUsers();
  }

  int getSubscriptionCount() {
    return _subscribeService.getSubscriptionCount();
  }

  void syncSubscribedUsersFromApi(
    Iterable<({String userId, String username})> apiUsers,
  ) {
    final apiIds = <String>{};
    _subscribeService.clearAll();

    for (final user in apiUsers) {
      if (user.userId.isEmpty) continue;
      apiIds.add(user.userId);
      _applyLocalState(
        user.userId,
        true,
        username: user.username,
        followStatus: 'following',
        notify: false,
      );
      _serverStates[user.userId] = true;
    }

    for (final userId in _users.keys.toList()) {
      if (!apiIds.contains(userId)) {
        _users.remove(userId);
        _serverStates.remove(userId);
      }
    }
    _log('🔄 syncSubscribedUsersFromApi count=${apiIds.length}');
  }

  void reset() {
    _users.clear();
    _serverStates.clear();
    _syncingUsers.clear();
    _pendingResyncUsers.clear();
    _subscribeService.clearAll();
    _log('🧹 reset complete');
  }

  void seedSubscribedFeedAuthors(
    Iterable<({String userId, String username})> authors, {
    bool notify = false,
  }) {
    var seeded = 0;
    for (final author in authors) {
      if (author.userId.isEmpty) continue;
      final existing = _users[author.userId];
      if (existing != null && !existing.isSubscribed) continue;
      _applyLocalState(
        author.userId,
        true,
        username: author.username,
        followStatus: 'following',
        notify: false,
      );
      seeded++;
    }
    if (notify && seeded > 0) notifyListeners();
  }

  void initializeUsers(List<Map<String, dynamic>> videoData) {
    for (final data in videoData) {
      final userId = (data['userId'] ?? data['username'] ?? '').toString();
      final username = (data['username'] ?? '').toString();
      final initialIsSubscribed = data['isSubscribed'] == true;

      if (userId.isNotEmpty && username.isNotEmpty) {
        addOrUpdateUser(
          SubscribeModel(
            userId: userId,
            username: username,
            isSubscribed: initialIsSubscribed,
            followStatus: initialIsSubscribed ? 'following' : 'none',
          ),
        );
      } else {
        _log('⚠️ skipped invalid initializeUsers row=$data');
      }
    }
  }

  @override
  void notifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      super.notifyListeners();
    });
  }
}

final subscribeNotifierProvider = Provider<SubscribeNotifier>(
  (ref) => SubscribeNotifier(),
);
