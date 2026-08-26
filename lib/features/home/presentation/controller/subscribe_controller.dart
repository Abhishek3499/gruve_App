import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gruve_app/core/app_navigator.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_count_refresh_bridge.dart';
import 'package:gruve_app/core/cache/cache_invalidation_service.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';

import 'package:gruve_app/features/user_profile/data/datasource/user_profile_service.dart';

import 'package:gruve_app/features/home/domain/entities/subscribe_model.dart';
import 'package:gruve_app/features/home/data/datasource/subscribe_service.dart';
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
      _log(
        '🔍 local state hit userId=$userId result=${localUser.isSubscribed}',
      );
      return localUser.isSubscribed;
    }

    final serviceState = _subscribeService.isUserSubscribed(userId);
    _log('🔍 service state hit userId=$userId result=$serviceState');
    return serviceState;
  }

  bool isSubscriptionSynced(String userId) {
    final local = isUserSubscribed(userId);
    final server = _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);
    return server == local;
  }

  SubscribeModel? getUserSubscribeModel(String userId) {
    final model = _users[userId];
    _log('🗂️ getUserSubscribeModel userId=$userId found=${model != null}');
    return model;
  }

  void addOrUpdateUser(SubscribeModel user) {
    _log(
      '🧩 addOrUpdateUser userId=${user.userId} username=${user.username} incoming=${user.isSubscribed}',
    );

    final existing = _users[user.userId];
    final localStatus = existing?.isSubscribed;
    // Trust API flags. Never upgrade an explicit local unsub; never use stale
    // in-memory service state to mark someone subscribed.
    final resolvedStatus = localStatus == false
        ? false
        : user.isSubscribed
            ? true
            : localStatus == true;

    _log(
      '🧠 resolved state userId=${user.userId} local=$localStatus incoming=${user.isSubscribed} final=$resolvedStatus',
    );

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
    _log(
      '📌 server baseline set userId=${user.userId} serverState=${_serverStates[user.userId]} localState=$resolvedStatus',
    );
    if (existing?.isSubscribed != resolvedStatus) {
      notifyListeners();
      _log('📣 listeners notified after addOrUpdateUser userId=${user.userId}');
    }
  }

  void _applyLocalState(
    String userId,
    bool isSubscribed, {
    String? username,
    bool notify = true,
  }) {
    _log(
      '⚡ _applyLocalState userId=$userId isSubscribed=$isSubscribed notify=$notify username=${username ?? '(keep)'}',
    );

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
      _log('📣 listeners notified after _applyLocalState userId=$userId');
    }
  }

  Future<void> _syncWithServer(String userId) async {
    if (_syncingUsers.contains(userId)) {
      _pendingResyncUsers.add(userId);
      _log('⏳ sync queued, already running for userId=$userId');
      return;
    }

    _log('🔄 sync start for userId=$userId');
    _syncingUsers.add(userId);
    var syncFailed = false;
    var iterations = 0;
    const maxIterations = 3;

    try {
      while (iterations < maxIterations) {
        iterations++;
        _log('🔄 sync loop iteration $iterations/$maxIterations for userId=$userId');

        final desiredState = isUserSubscribed(userId);

        // Fetch fresh ground-truth server state (bypass stale profile cache).
        _log('📡 sync fetching actual current server state for userId=$userId');
        unawaited(CacheManager().invalidatePattern(userId));
        final profileModel = await _userProfileService.getUserProfileModel(userId);
        final serverState = profileModel.isFollowing;

        // Update serverStates cache with the fresh value
        _serverStates[userId] = serverState;

        _log(
          '🪞 sync compare userId=$userId desired=$desiredState server=$serverState',
        );

        if (desiredState == serverState) {
          _log('✅ sync no-op, states already aligned for userId=$userId');
          break;
        }

        try {
          _log('📡 sync hitting server toggle for userId=$userId');
          final updatedServerState = await _subscribeService.toggleSubscription(
            userId,
          );
          _serverStates[userId] = updatedServerState;

          _log(
            '🎯 server returned userId=$userId updatedServerState=$updatedServerState',
          );

          if (isUserSubscribed(userId) == updatedServerState) {
            _log(
              '🤝 local matches server after response for userId=$userId, applying final state',
            );
            _applyLocalState(userId, updatedServerState);
          } else {
            _log(
              '🌀 local changed again during request for userId=$userId, keeping latest local state',
            );
          }

          await ProfileCountRefreshBridge.notifyCountsChanged(
            reason: updatedServerState
                ? 'user_subscribed'
                : 'user_unsubscribed',
          );
          _log('🔔 profile count refresh notified for userId=$userId');
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
      _log('🧹 sync finished for userId=$userId syncFailed=$syncFailed');

      final needsResync = _pendingResyncUsers.remove(userId);
      final desiredState = isUserSubscribed(userId);
      final serverState =
          _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);

      if (needsResync ||
          (!syncFailed && desiredState != serverState)) {
        _log(
          '🔁 sync rerun for userId=$userId desired=$desiredState server=$serverState queued=$needsResync',
        );
        unawaited(_syncWithServer(userId));
      }
    }
  }

  Future<bool> toggleSubscription(String userId) async {
    final optimisticStatus = !isUserSubscribed(userId);
    _log(
      '👆 toggleSubscription tapped userId=$userId optimisticStatus=$optimisticStatus',
    );
    _applyLocalState(userId, optimisticStatus);
    unawaited(_syncWithServer(userId));
    return optimisticStatus;
  }

  Future<bool> subscribeToUser(String userId) async {
    _log('➕ subscribeToUser userId=$userId');
    _applyLocalState(userId, true);
    unawaited(_syncWithServer(userId));
    return true;
  }

  Future<bool> unsubscribeFromUser(String userId) async {
    _log('➖ unsubscribeFromUser userId=$userId');
    _applyLocalState(userId, false);
    unawaited(_syncWithServer(userId));
    return false;
  }

  Set<String> getSubscribedUsers() {
    _log('📤 getSubscribedUsers called');
    return _subscribeService.getSubscribedUsers();
  }

  int getSubscriptionCount() {
    _log('🔢 getSubscriptionCount called');
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
    _log('🌱 seedSubscribedFeedAuthors seeded=$seeded notify=$notify');
    if (notify && seeded > 0) {
      notifyListeners();
    }
  }

  void initializeUsers(List<Map<String, dynamic>> videoData) {
    _log('🎬 initializeUsers count=${videoData.length}');
    for (final data in videoData) {
      final userId = (data['userId'] ?? data['username'] ?? '').toString();
      final username = (data['username'] ?? '').toString();
      final initialIsSubscribed = data['isSubscribed'] == true;

      if (userId.isNotEmpty && username.isNotEmpty) {
        _log(
          '🎯 initialize user userId=$userId username=$username initial=$initialIsSubscribed',
        );
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
