import 'package:flutter/foundation.dart';

import '../api/subscribe_api_service.dart';

class SubscribeService {
  static final SubscribeService _instance = SubscribeService._internal();
  factory SubscribeService() => _instance;
  SubscribeService._internal();

  final SubscribeApiService _apiService = SubscribeApiService();
  final Set<String> _subscribedUsers = {};

  void _log(String message) {
    debugPrint('🧰 [SubscribeService] $message');
  }

  bool isUserSubscribed(String userId) {
    final result = _subscribedUsers.contains(userId);
    _log('🔍 isUserSubscribed userId=$userId result=$result');
    return result;
  }

  void setSubscriptionStatus(String userId, bool isSubscribed) {
    _log('📝 setSubscriptionStatus userId=$userId isSubscribed=$isSubscribed');
    if (isSubscribed) {
      _subscribedUsers.add(userId);
    } else {
      _subscribedUsers.remove(userId);
    }
    _log('📚 local subscribed users count=${_subscribedUsers.length}');
  }

  Future<bool> toggleSubscription(String userId) async {
    _log('🚀 toggleSubscription start userId=$userId');
    final isSubscribed = await _apiService.toggleSubscription(userId);
    _log('🎯 API returned state=$isSubscribed for userId=$userId');
    setSubscriptionStatus(userId, isSubscribed);
    _log(
      '✅ toggleSubscription completed userId=$userId finalState=$isSubscribed',
    );
    return isSubscribed;
  }

  Future<bool> subscribeToUser(String userId) {
    return toggleSubscription(userId);
  }

  Future<bool> unsubscribeFromUser(String userId) {
    return toggleSubscription(userId);
  }

  Set<String> getSubscribedUsers() {
    _log('📤 getSubscribedUsers count=${_subscribedUsers.length}');
    return Set<String>.from(_subscribedUsers);
  }

  int getSubscriptionCount() {
    final count = _subscribedUsers.length;
    _log('🔢 getSubscriptionCount=$count');
    return count;
  }
}
