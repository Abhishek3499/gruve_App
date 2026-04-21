import 'dart:async';

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
  final Map<String, bool> _pendingDesiredStates = {};
  final Set<String> _syncingUsers = <String>{};

  bool isUserSubscribed(String userId) {
    final localUser = _users[userId];
    if (localUser != null) {
      return localUser.isSubscribed;
    }

    return _subscribeService.isUserSubscribed(userId);
  }

  SubscribeModel? getUserSubscribeModel(String userId) {
    return _users[userId];
  }

  void addOrUpdateUser(SubscribeModel user) {
    final existing = _users[user.userId];
    final cachedStatus = _subscribeService.isUserSubscribed(user.userId);
    final resolvedStatus =
        existing?.isSubscribed ?? (cachedStatus || user.isSubscribed);
    final resolvedUser = user.copyWith(
      username: user.username.isNotEmpty
          ? user.username
          : (existing?.username ?? user.userId),
      isSubscribed: resolvedStatus,
      subscribedAt: resolvedStatus
          ? (existing?.subscribedAt ?? user.subscribedAt ?? DateTime.now())
          : null,
    );

    _users[user.userId] = resolvedUser;
    _subscribeService.setSubscriptionStatus(user.userId, resolvedStatus);
    notifyListeners();
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

  Future<void> _syncPendingState(String userId) async {
    if (_syncingUsers.contains(userId)) {
      return;
    }

    _syncingUsers.add(userId);

    try {
      while (true) {
        final desiredState = _pendingDesiredStates.remove(userId);
        if (desiredState == null) {
          break;
        }

        try {
          final serverState = desiredState
              ? await _subscribeService.subscribeToUser(userId)
              : await _subscribeService.unsubscribeFromUser(userId);

          _applyLocalState(userId, serverState);
          await ProfileCountRefreshBridge.notifyCountsChanged(
            reason: desiredState ? 'user_subscribed' : 'user_unsubscribed',
          );
        } catch (e) {
          print("ERROR SYNCING SUBSCRIPTION FOR $userId: $e");
        }
      }
    } finally {
      _syncingUsers.remove(userId);
      if (_pendingDesiredStates.containsKey(userId)) {
        unawaited(_syncPendingState(userId));
      }
    }
  }

  Future<bool> toggleSubscription(String userId) async {
    final optimisticStatus = !isUserSubscribed(userId);
    _applyLocalState(userId, optimisticStatus);
    _pendingDesiredStates[userId] = optimisticStatus;
    unawaited(_syncPendingState(userId));
    return optimisticStatus;
  }

  Future<bool> subscribeToUser(String userId) async {
    _applyLocalState(userId, true);
    _pendingDesiredStates[userId] = true;
    unawaited(_syncPendingState(userId));
    return true;
  }

  Future<bool> unsubscribeFromUser(String userId) async {
    _applyLocalState(userId, false);
    _pendingDesiredStates[userId] = false;
    unawaited(_syncPendingState(userId));
    return false;
  }

  Set<String> getSubscribedUsers() {
    return _subscribeService.getSubscribedUsers();
  }

  int getSubscriptionCount() {
    return _subscribeService.getSubscriptionCount();
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
      }
    }
  }
}
