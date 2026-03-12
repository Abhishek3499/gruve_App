class SubscribeService {
  static final SubscribeService _instance = SubscribeService._internal();
  factory SubscribeService() => _instance;
  SubscribeService._internal();

  // In-memory storage for subscribed users
  final Set<String> _subscribedUsers = {};

  // Check if user is subscribed
  bool isUserSubscribed(String userId) {
    return _subscribedUsers.contains(userId);
  }

  // Subscribe to user
  void subscribeToUser(String userId) {
    _subscribedUsers.add(userId);
  }

  // Unsubscribe from user
  void unsubscribeFromUser(String userId) {
    _subscribedUsers.remove(userId);
  }

  // Toggle subscription
  bool toggleSubscription(String userId) {
    if (isUserSubscribed(userId)) {
      unsubscribeFromUser(userId);
      return false;
    } else {
      subscribeToUser(userId);
      return true;
    }
  }

  // Get all subscribed users
  Set<String> getSubscribedUsers() {
    return Set.from(_subscribedUsers);
  }

  // Get subscription count
  int getSubscriptionCount() {
    return _subscribedUsers.length;
  }
}
