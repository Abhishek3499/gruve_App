import 'package:gruve_app/core/utils/app_logger.dart';

class PostItem {
  final String id;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;

  const PostItem({
    required this.id,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) {
    return PostItem(
      id: json['id']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? json['url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString(),
      caption: json['caption']?.toString(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }
}

class UserProfile {
  final String userId;
  final String username;
  final String fullName;
  final String profilePicture;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isPrivate;
  final bool isFollowing;
  final bool hasActiveStory;
  final List<dynamic> highlights;
  final List<PostItem> allPosts;
  final List<PostItem> likedPosts;

  const UserProfile({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.profilePicture,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isPrivate,
    required this.isFollowing,
    this.hasActiveStory = false,
    this.highlights = const [],
    this.allPosts = const [],
    this.likedPosts = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    AppLogger.d('🔄 [UserProfile] Parsing profile from JSON...');
    AppLogger.d('[UserProfile] Top level keys: ${json.keys.toList()}');

    try {
      // ✅ Service already extracted 'data' layer — so start from 'user' directly
      final user = json['user'] as Map<String, dynamic>;
      final stats = (user['stats'] ?? {}) as Map<String, dynamic>;
      
      // Posts parsing
      final posts = (json['posts'] ?? {}) as Map<String, dynamic>;
      final allPosts = (posts['all'] ?? {}) as Map<String, dynamic>;
      final likedPosts = (posts['likes'] ?? {}) as Map<String, dynamic>;
      
      final allResults = (allPosts['results'] as List<dynamic>? ?? [])
          .map((e) => PostItem.fromJson(e as Map<String, dynamic>))
          .toList();
          
      final likedResults = (likedPosts['results'] as List<dynamic>? ?? [])
          .map((e) => PostItem.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.d('✅ [UserProfile] userId: ${user['id']}');
      AppLogger.d('✅ [UserProfile] username: ${user['username']}');
      AppLogger.d('✅ [UserProfile] subscribers: ${stats['subscribers_count']}');
      AppLogger.d('✅ [UserProfile] allPosts: ${allResults.length}');

      return UserProfile(
        userId:         user['id']?.toString() ?? '',
        username:       user['username']?.toString() ?? '',
        fullName:       user['full_name']?.toString() ?? '',
        profilePicture: _pickString(user, const [
          'profile_picture',
          'profileImage',
          'profile_image',
          'avatar',
          'photo',
          'image',
        ]),
        bio:            user['bio']?.toString() ?? '',
        followersCount: stats['subscribers_count'] as int? ?? 0,
        followingCount: stats['likes_count'] as int? ?? 0,
        postsCount:     stats['videos_count'] as int? ?? 0,
        isPrivate:      user['is_private'] as bool? ?? false,
        isFollowing:    user['is_subscribed'] as bool? ?? false,
        hasActiveStory: json['has_active_story'] as bool? ?? false,
        highlights:     json['highlights'] as List<dynamic>? ?? [],
        allPosts:       allResults,
        likedPosts:     likedResults,
      );
    } catch (e) {
      AppLogger.d('❌ [UserProfile] Error parsing profile: $e');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, username: $username, fullName: $fullName, followersCount: $followersCount, followingCount: $followingCount, postsCount: $postsCount, isPrivate: $isPrivate, isFollowing: $isFollowing, hasActiveStory: $hasActiveStory, highlights: ${highlights.length}, allPosts: ${allPosts.length}, likedPosts: ${likedPosts.length})';
  }
}

String _pickString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final stringValue = value.toString().trim();
    if (stringValue.isNotEmpty && stringValue.toLowerCase() != 'null') {
      return stringValue;
    }
  }
  return '';
}
