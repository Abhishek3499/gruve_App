import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';

import 'package:gruve_app/features/user_profile/data/datasource/user_profile_service.dart';

import 'package:gruve_app/features/home/data/models/subscribe_model.dart';
import 'package:gruve_app/features/home/data/services/subscribe_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class SubscribeController extends ChangeNotifier {
  static final SubscribeController _instance = SubscribeController._internal();
  factory SubscribeController() => _instance;
  SubscribeController._internal();

  final SubscribeService _subscribeService = SubscribeService();
  final UserProfileService _userProfileService = UserProfileService();
  final Map<String, SubscribeModel> _users = {};
  final Map<String, bool> _serverStates = {};
  final Set<String> _syncingUsers = <String>{};
  final Set<String> _pendingResyncUsers = <String>{};

  Map<String, SubscribeModel> get users => Map.unmodifiable(_users);

  void _log(String message) {
    AppLogger.d('🎛️ [SubscribeController] $message');
  }

  bool isUserSubscribed(String userId) {
    final localUser = _users[userId];
    if (localUser != null) {
      return localUser.isSubscribed;
    }
    return _subscribeService.isUserSubscribed(userId);
  }

  bool isSubscriptionSynced(String userId) {
    final local = isUserSubscribed(userId);
    final server = _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);
    return server == local;
  }

  SubscribeModel? getUserSubscribeModel(String userId) {
    return _users[userId];
  }

  void addOrUpdateUser(SubscribeModel user) {
    final existing = _users[user.userId];
    final localStatus = existing?.isSubscribed;
    // Trust API flags. Never upgrade an explicit local unsub; never use stale
    // in-memory service state to mark someone subscribed.
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
    // Only notify on a genuine flip of a previously-known user's status.
    // First-time discovery (existing == null) happens constantly during
    // normal scrolling/profile views as feed/profile data seeds this map —
    // that is not a subscription change and must not trigger listeners
    // (e.g. VideoFeedController's feed-refresh-on-subscription-change).
    if (existing != null && existing.isSubscribed != resolvedStatus) {
      notifyListeners();
    }
  }

  void _applyLocalState(
    String userId,
    bool isSubscribed, {
    String? username,
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
      subscribedAt: isSubscribed
          ? (existing?.subscribedAt ?? DateTime.now())
          : null,
    );
    _subscribeService.setSubscriptionStatus(userId, isSubscribed);

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _syncWithServer(String userId) async {
    if (_syncingUsers.contains(userId)) {
      _pendingResyncUsers.add(userId);
      return;
    }

    _syncingUsers.add(userId);
    var syncFailed = false;
    var iterations = 0;
    const maxIterations = 3;

    try {
      while (iterations < maxIterations) {
        iterations++;

        final desiredState = isUserSubscribed(userId);

        // Fetch fresh ground-truth server state (bypass stale profile cache).
        unawaited(CacheManager().invalidatePattern(userId));
        final profileModel = await _userProfileService.getUserProfileModel(userId);
        final serverState = profileModel.isFollowing;

        // Update serverStates cache with the fresh value
        _serverStates[userId] = serverState;

        if (desiredState == serverState) {
          break;
        }

        try {
          final updatedServerState = await _subscribeService.toggleSubscription(
            userId,
          );
          _serverStates[userId] = updatedServerState;

          if (isUserSubscribed(userId) == updatedServerState) {
            _applyLocalState(userId, updatedServerState);
          }

          await ProfileCountRefreshBridge.notifyCountsChanged(
            reason: updatedServerState
                ? 'user_subscribed'
                : 'user_unsubscribed',
          );
          unawaited(CacheInvalidationService().onUserFollowed(userId));
        } catch (e) {
          _log('❌ sync failed for userId=$userId error=$e');
          syncFailed = true;

          // Revert local state back to the correct server state
          final latestServerState = _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);
          _applyLocalState(userId, latestServerState);

          // Show floating SnackBar for error feedback using global ScaffoldMessenger state
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Something went wrong'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
        }
      }

      if (iterations >= maxIterations) {
        final desiredState = isUserSubscribed(userId);
        final finalServerState = _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);
        if (desiredState != finalServerState) {
          _log('⚠️ [SubscribeController] Warning: reached max iterations ($maxIterations) for userId=$userId without aligning states (desired=$desiredState, server=$finalServerState)');
        }
      }
    } finally {
      _syncingUsers.remove(userId);

      final needsResync = _pendingResyncUsers.remove(userId);
      final desiredState = isUserSubscribed(userId);
      final serverState =
          _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);

      if (needsResync ||
          (!syncFailed && desiredState != serverState)) {
        unawaited(_syncWithServer(userId));
      }
    }
  }

  Future<bool> toggleSubscription(String userId) async {
    final optimisticStatus = !isUserSubscribed(userId);
    _applyLocalState(userId, optimisticStatus);
    unawaited(_syncWithServer(userId));
    return optimisticStatus;
  }

  Future<bool> subscribeToUser(String userId) async {
    _applyLocalState(userId, true);
    unawaited(_syncWithServer(userId));
    return true;
  }

  Future<bool> unsubscribeFromUser(String userId) async {
    _applyLocalState(userId, false);
    unawaited(_syncWithServer(userId));
    return false;
  }

  Set<String> getSubscribedUsers() {
    return _subscribeService.getSubscribedUsers();
  }

  int getSubscriptionCount() {
    return _subscribeService.getSubscriptionCount();
  }

  /// Align in-memory subscription state with the subscribed-users API response.
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

  /// Clears all subscription memory (call on logout / new login).
  void reset() {
    _users.clear();
    _serverStates.clear();
    _syncingUsers.clear();
    _pendingResyncUsers.clear();
    _subscribeService.clearAll();
    _log('🧹 reset complete');
  }

  /// Trusts the subscribed-feed API and marks authors as subscribed locally.
  /// Without this, missing `is_subscribed` flags make the feed strip every post.
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
        notify: false,
      );
      seeded++;
    }
    if (notify && seeded > 0) {
      notifyListeners();
    }
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
