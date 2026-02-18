import 'models/user_model.dart';

class DummyUsers {
  // Get all available users
  static List<UserModel> getAllUsers() {
    return [
      UserModel.currentUser(),
      UserModel.otherUser('user_001'),
      UserModel.otherUser('user_002'),
      UserModel.otherUser('user_003'),
    ];
  }

  // Get current user
  static UserModel getCurrentUser() {
    return UserModel.currentUser();
  }

  // Get user by ID
  static UserModel getUserById(String userId) {
    return UserModel.otherUser(userId);
  }

  // Get users except current user
  static List<UserModel> getOtherUsers() {
    return [
      UserModel.otherUser('user_001'),
      UserModel.otherUser('user_002'),
      UserModel.otherUser('user_003'),
    ];
  }

  // Get subscribed users
  static List<UserModel> getSubscribedUsers() {
    return getAllUsers()
        .where((user) => user.isSubscribed && !user.isCurrentUser)
        .toList();
  }

  // Get unsubscribed users
  static List<UserModel> getUnsubscribedUsers() {
    return getAllUsers()
        .where((user) => !user.isSubscribed && !user.isCurrentUser)
        .toList();
  }

  // Toggle subscription status (for demo purposes)
  static UserModel toggleSubscription(UserModel user) {
    if (user.isCurrentUser) return user; // Can't subscribe to yourself
    
    return user.copyWith(isSubscribed: !user.isSubscribed);
  }

  // Search users by username or handle
  static List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return getAllUsers();
    
    final lowercaseQuery = query.toLowerCase();
    return getAllUsers().where((user) =>
        user.username.toLowerCase().contains(lowercaseQuery) ||
        user.handle.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
}
