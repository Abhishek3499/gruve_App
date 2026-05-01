import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/controller/profile_count_refresh_bridge.dart';

import '../models/subscribe_model.dart';
import '../services/subscribe_service.dart';

class SubscribeController extends ChangeNotifier {
  static final SubscribeController _instance = SubscribeController._internal();
  factory SubscribeController() => _instance;
  SubscribeController._internal();

  final SubscribeService _subscribeService = SubscribeService();
  final Map<String, SubscribeModel> _users = {};
  final Map<String, bool> _serverStates = {};
  final Set<String> _syncingUsers = <String>{};

  void _log(String message) {
    debugPrint('🎛️ [SubscribeController] $message');
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
    final cachedStatus = _subscribeService.isUserSubscribed(user.userId);
    final resolvedStatus = localStatus ?? (cachedStatus || user.isSubscribed);

    _log(
      '🧠 resolved state userId=${user.userId} local=$localStatus cached=$cachedStatus incoming=${user.isSubscribed} final=$resolvedStatus',
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

    _serverStates[user.userId] = user.isSubscribed;
    _subscribeService.setSubscriptionStatus(user.userId, resolvedStatus);
    _log(
      '📌 server baseline set userId=${user.userId} serverState=${user.isSubscribed} localState=$resolvedStatus',
    );
    notifyListeners();
    _log('📣 listeners notified after addOrUpdateUser userId=${user.userId}');
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
      _log('⏳ sync skipped, already running for userId=$userId');
      return;
    }

    _log('🔄 sync start for userId=$userId');
    _syncingUsers.add(userId);
    var syncFailed = false;

    try {
      while (true) {
        final desiredState = isUserSubscribed(userId);
        final serverState =
            _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);

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
        } catch (e) {
          _log('❌ sync failed for userId=$userId error=$e');
          syncFailed = true;
          break;
        }
      }
    } finally {
      _syncingUsers.remove(userId);
      _log('🧹 sync finished for userId=$userId syncFailed=$syncFailed');

      final desiredState = isUserSubscribed(userId);
      final serverState =
          _serverStates[userId] ?? _subscribeService.isUserSubscribed(userId);

      if (!syncFailed && desiredState != serverState) {
        _log(
          '🔁 state changed during sync, rerunning for userId=$userId desired=$desiredState server=$serverState',
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
}
