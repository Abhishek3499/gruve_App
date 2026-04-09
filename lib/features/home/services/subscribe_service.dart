import '../api/subscribe_api_service.dart';

class SubscribeService {
  static final SubscribeService _instance = SubscribeService._internal();
  factory SubscribeService() => _instance;
  SubscribeService._internal();

  final SubscribeApiService _apiService = SubscribeApiService();

  // In-memory storage for subscribed users (backup/cache)
  final Set<String> _subscribedUsers = {};

  // Check if user is subscribed
  bool isUserSubscribed(String userId) {
    print("🔍 CHECKING SUBSCRIPTION STATUS FOR USER: $userId");
    print("💾 LOCAL CACHE STATUS: ${_subscribedUsers.contains(userId)}");
    return _subscribedUsers.contains(userId);
  }

  // Subscribe to user (API call)
  Future<bool> subscribeToUser(String userId) async {
    try {
      print("📡 SUBSCRIBING TO USER: $userId");
      final isSubscribed = await _apiService.subscribeToUser(userId);
      
      if (isSubscribed) {
        _subscribedUsers.add(userId);
        print("✅ SUCCESSFULLY SUBSCRIBED TO USER: $userId");
      } else {
        print("⚠️ SUBSCRIPTION FAILED FOR USER: $userId");
      }
      
      return isSubscribed;
    } catch (e) {
      print("❌ ERROR SUBSCRIBING TO USER $userId: $e");
      rethrow;
    }
  }

  // Unsubscribe from user (API call)
  Future<bool> unsubscribeFromUser(String userId) async {
    try {
      print("🚫 UNSUBSCRIBING FROM USER: $userId");
      final isSubscribed = await _apiService.unsubscribeFromUser(userId);
      
      if (!isSubscribed) {
        _subscribedUsers.remove(userId);
        print("✅ SUCCESSFULLY UNSUBSCRIBED FROM USER: $userId");
      } else {
        print("⚠️ UNSUBSCRIPTION FAILED FOR USER: $userId");
      }
      
      return isSubscribed;
    } catch (e) {
      print("❌ ERROR UNSUBSCRIBING FROM USER $userId: $e");
      rethrow;
    }
  }

  // Set subscription manually (Optimistic UI support)
  void setSubscriptionStatus(String userId, bool isSubscribed) {
    if (isSubscribed) {
      _subscribedUsers.add(userId);
    } else {
      _subscribedUsers.remove(userId);
    }
  }

  // Toggle subscription (API call)
  Future<bool> toggleSubscription(String userId) async {
    final wasSubscribed = _subscribedUsers.contains(userId);
    
    // Optimistic UI update
    setSubscriptionStatus(userId, !wasSubscribed);

    try {
      print("🔄 CALLING API TO TOGGLE SUBSCRIPTION FOR USER: $userId");
      final isSubscribed = await _apiService.toggleSubscription(userId, wasSubscribed);
      
      // Update with final server truth
      setSubscriptionStatus(userId, isSubscribed);
      return isSubscribed;
    } catch (e) {
      print("❌ ERROR TOGGLING SUBSCRIPTION FOR USER $userId: $e");
      // Removed revert
      rethrow;
    }
  }

  // Get all subscribed users
  Set<String> getSubscribedUsers() {
    print("📋 GETTING ALL SUBSCRIBED USERS: ${_subscribedUsers.length} users");
    return Set.from(_subscribedUsers);
  }

  // Get subscription count
  int getSubscriptionCount() {
    print("📊 SUBSCRIPTION COUNT: ${_subscribedUsers.length}");
    return _subscribedUsers.length;
  }
}
