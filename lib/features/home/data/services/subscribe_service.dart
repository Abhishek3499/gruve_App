import 'package:gruve_app/features/home/data/services/subscribe_api_service.dart';
import 'package:gruve_app/features/user_profile/data/datasource/user_profile_service.dart';

class SubscribeService {
  static final SubscribeService _instance = SubscribeService._internal();
  factory SubscribeService() => _instance;
  SubscribeService._internal();

  final SubscribeApiService _apiService = SubscribeApiService();
  final UserProfileService _userProfileService = UserProfileService();
  final Set<String> _subscribedUsers = {};

  bool isUserSubscribed(String userId) {
    return _subscribedUsers.contains(userId);
  }

  void setSubscriptionStatus(String userId, bool isSubscribed) {
    if (isSubscribed) {
      _subscribedUsers.add(userId);
    } else {
      _subscribedUsers.remove(userId);
    }
  }

  Future<({bool isFollowing, String followStatus})> toggleSubscription(String userId) async {
    final result = await _apiService.toggleSubscription(userId);
    setSubscriptionStatus(userId, result.isFollowing);
    return result;
  }

  Future<bool> subscribeToUser(String userId) async {
    final profile = await _userProfileService.getUserProfileModel(userId);
    if (profile.isFollowing) return true;
    final result = await toggleSubscription(userId);
    return result.isFollowing;
  }

  Future<bool> unsubscribeFromUser(String userId) async {
    final profile = await _userProfileService.getUserProfileModel(userId);
    if (!profile.isFollowing) return false;
    final result = await toggleSubscription(userId);
    return result.isFollowing;
  }

  Set<String> getSubscribedUsers() {
    return Set<String>.from(_subscribedUsers);
  }

  int getSubscriptionCount() {
    return _subscribedUsers.length;
  }

  void clearAll() {
    _subscribedUsers.clear();
  }
}
