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

  // Toggle subscription
  bool toggleSubscription(String userId) {
    final isSubscribed = _subscribeService.toggleSubscription(userId);
    
    // Update user model if exists
    if (_users.containsKey(userId)) {
      final currentUser = _users[userId]!;
      _users[userId] = currentUser.copyWith(
        isSubscribed: isSubscribed,
        subscribedAt: isSubscribed ? DateTime.now() : null,
      );
    }
    
    notifyListeners();
    return isSubscribed;
  }

  // Subscribe to user
  void subscribeToUser(String userId) {
    _subscribeService.subscribeToUser(userId);
    
    if (_users.containsKey(userId)) {
      final currentUser = _users[userId]!;
      _users[userId] = currentUser.copyWith(
        isSubscribed: true,
        subscribedAt: DateTime.now(),
      );
    }
    
    notifyListeners();
  }

  // Unsubscribe from user
  void unsubscribeFromUser(String userId) {
    _subscribeService.unsubscribeFromUser(userId);
    
    if (_users.containsKey(userId)) {
      final currentUser = _users[userId]!;
      _users[userId] = currentUser.copyWith(
        isSubscribed: false,
        subscribedAt: null,
      );
    }
    
    notifyListeners();
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
