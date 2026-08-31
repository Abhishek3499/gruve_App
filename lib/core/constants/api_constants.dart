import 'package:gruve_app/core/config/environment_config.dart';

/// Central registry of every backend API endpoint path used by the app.
///
/// Paths are relative to [baseUrl] unless noted otherwise.
/// Keep this file as the single source of truth when adding or renaming
/// endpoints so folder/feature restructuring never has to hunt for literals.
class ApiConstants {
  const ApiConstants._();

  /// Active API base URL, read from .env via [EnvironmentConfig].
  static String get baseUrl => EnvironmentConfig.baseUrl;

  /// Active WebSocket URL, read from .env via [EnvironmentConfig].
  static String get wsUrl => EnvironmentConfig.wsUrl;

  // ---- Auth ----
  static const String login = 'auth/login/';
  static const String googleSignIn = 'auth/google/';
  static const String signup = 'auth/signup/';
  static const String verifyOtp = 'auth/verify-otp/';
  static const String resendOtp = 'auth/resend-otp/';
  static const String forgotPassword = 'auth/forgot-password/';
  static const String resetPassword = 'auth/reset-password/';
  static const String logout = 'auth/logout/';
  static const String completeProfile = 'auth/complete-profile/';
  static const String refreshToken = '/auth/refresh';
  static const String passwordResetVerifyOtp =
      'auth/password-reset/verify-otp';
  static const String passwordResetConfirm = 'auth/password/reset/confirm';

  // ---- User / Profile ----
  static const String fetchProfile = 'user/edit_profile';
  static const String updateProfile = 'user/edit_profile/';
  static const String profileData = 'user/profile_data/';
  static const String userSearch = 'user/users/search/';
  static const String users = 'user/users/';
  static String userProfile(String userId) => 'user/profile/$userId/';

  // ---- Subscribe / Block / Report ----
  static const String subscribeToggle = 'profile/subscribe/toggle';
  static const String reportUser = 'profile/report/';
  static const String blockList = 'profile/block/list';
  static const String blockToggle = 'profile/block/toggle';

  // ---- Comments ----
  static const String comments = 'posts/comments/';

  // ---- Highlights ----
  static const String myHighlights = 'highlights/mine/';
  static const String createHighlight = 'highlights/';
  static String highlightStories(String highlightId) =>
      'highlights/$highlightId/stories/';

  // ---- Explore ----
  static const String exploreReels = 'explore/reels/';

  // ---- Notifications ----
  static const String notifications = 'notifications/';
  static const String notificationsUnreadCount = 'notifications/unread-count/';
  static const String notificationsMarkRead = 'notifications/mark-read/';

  // ---- Conversations / Messages ----
  static const String conversations = '/conversations/';
  static String conversationMessages(String conversationId) =>
      '/conversations/$conversationId/messages/';
  static String conversationMessagesMedia(String conversationId) =>
      '/conversations/$conversationId/messages/media/';
  static String conversationMessagesRead(String conversationId) =>
      '/conversations/$conversationId/messages/read';
  static String conversationMessage(
    String conversationId,
    String messageId,
  ) => '/conversations/$conversationId/messages/$messageId';

  // ---- Stories ----
  static const String stories = 'stories/';
  static const String myStories = 'stories/me/';
  static String userStories(String userId) => 'stories/user/$userId/';

  // ---- Posts ----
  static const String createPost = 'posts/create-post/';
  static const String postDrafts = 'posts/drafts/';
  static const String postLikeToggle = 'posts/like/toggle/';
  static const String postShare = 'posts/share/';
  static const String postSaveToggle = 'posts/save/toggle/';
  static const String savedPosts = 'posts/saved/';
  static const String getPost = 'posts/get-post/';
  static String postDraft(String draftId) => 'posts/drafts/$draftId/';
  static String post(String postId) => 'posts/$postId/';
}
