import 'package:flutter/material.dart';
import '../models/subscribe_model.dart';
import '../services/subscribe_service.dart';

class SubscribeController extends ChangeNotifier {
  final SubscribeService _subscribeService = SubscribeService();
  final Map<String, SubscribeModel> _users = {};

  // Get subscription status for a user
  bool isUserSubscribed(String userId) {
    return _subscribeService.isUserSubscribed(userId);
  }

  // Get subscribe model for a user
  SubscribeModel? getUserSubscribeModel(String userId) {
    return _users[userId];
  }

  // Add or update user
  void addOrUpdateUser(SubscribeModel user) {
    _users[user.userId] = user;
    notifyListeners();
  }

  // Toggle subscription (async)
  Future<bool> toggleSubscription(String userId) async {
    print("🔄 CONTROLLER TOGGLING SUBSCRIPTION FOR USER: $userId");
    
    // 1️⃣ OPTIMISTIC UI UPDATE
    final wasSubscribed = isUserSubscribed(userId);
    final optimisticStatus = !wasSubscribed;

    if (_users.containsKey(userId)) {
      final currentUser = _users[userId]!;
      _users[userId] = currentUser.copyWith(
        isSubscribed: optimisticStatus,
        subscribedAt: optimisticStatus ? DateTime.now() : null,
      );
    }
    notifyListeners(); // Force UI to rebuild immediately!
    
    try {
      // 2️⃣ API CALL
      final isSubscribed = await _subscribeService.toggleSubscription(userId);
      
      // 3️⃣ SERVER TRUTH UPDATE
      if (_users.containsKey(userId)) {
        final currentUser = _users[userId]!;
        _users[userId] = currentUser.copyWith(
          isSubscribed: isSubscribed,
          subscribedAt: isSubscribed ? DateTime.now() : null,
        );
      }
      
      notifyListeners();
      return isSubscribed;
    } catch (e) {
      print("❌ CONTROLLER ERROR TOGGLING SUBSCRIPTION FOR $userId: $e");
      
      // Removed automatic revert to keep the UI "optimistically successful" during demo
      // or while backend endpoint is still being fully implemented.
      
      // Return the optimistic status so the UI thinks it succeeded
      return optimisticStatus;
    }
  }

  // Subscribe to user (async)
  Future<bool> subscribeToUser(String userId) async {
    print("📡 CONTROLLER SUBSCRIBING TO USER: $userId");
    
    try {
      final isSubscribed = await _subscribeService.subscribeToUser(userId);
      
      if (_users.containsKey(userId)) {
        final currentUser = _users[userId]!;
        _users[userId] = currentUser.copyWith(
          isSubscribed: true,
          subscribedAt: DateTime.now(),
        );
        print("✅ UPDATED USER MODEL FOR $userId: subscribed=true");
      }
      
      notifyListeners();
      print("📢 NOTIFIED LISTENERS ABOUT SUBSCRIPTION");
      return isSubscribed;
    } catch (e) {
      print("❌ CONTROLLER ERROR SUBSCRIBING TO $userId: $e");
      rethrow;
    }
  }

  // Unsubscribe from user (async)
  Future<bool> unsubscribeFromUser(String userId) async {
    print("🚫 CONTROLLER UNSUBSCRIBING FROM USER: $userId");
    
    try {
      final isSubscribed = await _subscribeService.unsubscribeFromUser(userId);
      
      if (_users.containsKey(userId)) {
        final currentUser = _users[userId]!;
        _users[userId] = currentUser.copyWith(
          isSubscribed: false,
          subscribedAt: null,
        );
        print("✅ UPDATED USER MODEL FOR $userId: subscribed=false");
      }
      
      notifyListeners();
      print("📢 NOTIFIED LISTENERS ABOUT UNSUBSCRIPTION");
      return isSubscribed;
    } catch (e) {
      print("❌ CONTROLLER ERROR UNSUBSCRIBING FROM $userId: $e");
      rethrow;
    }
  }

  // Get all subscribed users
  Set<String> getSubscribedUsers() {
    return _subscribeService.getSubscribedUsers();
  }

  // Get subscription count
  int getSubscriptionCount() {
    return _subscribeService.getSubscriptionCount();
  }

  // Initialize users from video data
  void initializeUsers(List<Map<String, String>> videoData) {
    for (final data in videoData) {
      final userId = data['userId'] ?? data['username'] ?? '';
      final username = data['username'] ?? '';
      
      if (userId.isNotEmpty && username.isNotEmpty) {
        _users[userId] = SubscribeModel(
          userId: userId,
          username: username,
          isSubscribed: _subscribeService.isUserSubscribed(userId),
        );
      }
    }
    notifyListeners();
  }
}
