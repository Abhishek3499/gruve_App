import 'package:gruve_app/core/parsing/safe_parsing_helpers.dart';

class ProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String profileImage;
  final String bio;
  final bool isFollowing;
  final bool hasActiveStory;
  final bool hasCloseFriendsStory;
  final int storyCount;
  final int unreadNotificationCount;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.profileImage,
    this.bio = '',
    this.isFollowing = false,
    this.hasActiveStory = false,
    this.hasCloseFriendsStory = false,
    this.storyCount = 0,
    this.unreadNotificationCount = 0,
  });

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? profileImage,
    String? bio,
    bool? isFollowing,
    bool? hasActiveStory,
    bool? hasCloseFriendsStory,
    int? storyCount,
    int? unreadNotificationCount,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      isFollowing: isFollowing ?? this.isFollowing,
      hasActiveStory: hasActiveStory ?? this.hasActiveStory,
      hasCloseFriendsStory: hasCloseFriendsStory ?? this.hasCloseFriendsStory,
      storyCount: storyCount ?? this.storyCount,
      unreadNotificationCount:
          unreadNotificationCount ?? this.unreadNotificationCount,
    );
  }

  /// Overlays nested `data` / `user` / `profile` fields so top-level keys resolve.
  static Map<String, dynamic> flattenUserJson(Map<String, dynamic> json) {
    final safeJson = SafeParsingHelpers.validateAndCleanMap(
      json,
      context: 'ProfileModel.flattenUserJson',
    );
    final base = Map<String, dynamic>.from(safeJson);

    void overlay(dynamic node) {
      if (node is! Map) return;
      final safeNode = SafeParsingHelpers.validateAndCleanMap(
        node,
        context: 'ProfileModel.flattenUserJson.overlay',
      );
      safeNode.forEach((k, v) {
        if (v == null) return;
        if (v is String && v.trim().isEmpty) return;
        final existing = base[k];
        final existingEmpty =
            existing == null ||
            (existing is String && existing.toString().trim().isEmpty);
        if (existingEmpty) {
          base[k] = v;
        }
      });
    }

    overlay(safeJson['data']);
    overlay(safeJson['user']);
    overlay(safeJson['profile']);
    if (safeJson['data'] is Map) {
      final d = SafeParsingHelpers.validateAndCleanMap(
        safeJson['data'],
        context: 'ProfileModel.flattenUserJson.data',
      );
      overlay(d['user']);
      overlay(d['profile']);
    }

    return base;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final safeJson = SafeParsingHelpers.validateAndCleanMap(
      json,
      context: 'ProfileModel.fromJson',
    );
    final flat = flattenUserJson(safeJson);

    final fullName = SafeParsingHelpers.safeString(flat, const [
      'full_name',
      'fullname',
      'display_name',
      'name',
      'first_name',
    ], fallback: '');

    var username = SafeParsingHelpers.safeString(flat, const [
      'username',
      'user_name',
      'handle',
    ], fallback: '');

    if (username.isEmpty) {
      username = '';
    }

    final profileImage = SafeParsingHelpers.safeString(flat, const [
      'profile_picture',
      'profile_image',
      'avatar',
      'photo',
      'image',
    ], fallback: '');

    final id = SafeParsingHelpers.safeString(flat, const [
      'id',
      'user_id',
      'pk',
    ], fallback: "");

    final isFollowing = SafeParsingHelpers.safeBool(flat, const [
      'is_following',
      'is_subscribed',
      'following',
      'subscribed',
    ], fallback: false);

    final parsedHasActiveStory = SafeParsingHelpers.safeBool(flat, const [
      'has_active_story',
      'has_story',
      'story_active',
      'has_stories',
    ], fallback: false);

    final hasCloseFriendsStory = SafeParsingHelpers.safeBool(flat, const [
      'has_close_friends_story',
      'has_close_friend_story',
      'close_friends_story',
    ], fallback: false);

    final storyCount = SafeParsingHelpers.safeInt(flat, const [
      'story_count',
      'stories_count',
      'storyCount',
      'storiesCount',
    ], fallback: 0);

    final unreadNotificationCount = SafeParsingHelpers.safeInt(flat, const [
      'unread_notification_count',
      'unread_notifications_count',
    ], fallback: 0);

    final hasActiveStory = parsedHasActiveStory;

    final bio = SafeParsingHelpers.safeString(flat, const [
      'bio',
      'about',
      'description',
    ], fallback: '');

    final model = ProfileModel(
      id: id,
      fullName: fullName,
      username: username,
      profileImage: profileImage,
      bio: bio,
      isFollowing: isFollowing,
      hasActiveStory: hasActiveStory,
      hasCloseFriendsStory: hasCloseFriendsStory,
      storyCount: storyCount,
      unreadNotificationCount: unreadNotificationCount,
    );

    return model;
  }
}
