import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';

class ExploreStoryUser {
  final String id;
  final String username;
  final String fullName;
  final String profilePicture;

  const ExploreStoryUser({
    required this.id,
    required this.username,
    this.fullName = '',
    this.profilePicture = '',
  });

  String get displayName => fullName.trim().isNotEmpty ? fullName : username;

  factory ExploreStoryUser.fromJson(Map<String, dynamic> json) {
    return ExploreStoryUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      profilePicture: Post.normalizeMediaUrl(
        json['profile_picture']?.toString() ?? '',
      ),
    );
  }
}

/// One tray entry: a user plus a preview of their latest story. The playable
/// files are loaded on tap through the existing stories API.
class ExploreStory {
  final String storyId;

  /// Null when the preview story is a video with no saved thumbnail.
  final String? thumbnail;
  final int storyCount;
  final bool hasUnseenStory;
  final bool hasCloseFriendsStory;
  final ExploreStoryUser user;

  const ExploreStory({
    required this.storyId,
    this.thumbnail,
    this.storyCount = 1,
    this.hasUnseenStory = false,
    this.hasCloseFriendsStory = false,
    required this.user,
  });

  /// Card image — the story thumbnail, else the avatar.
  String get cardImage {
    final thumb = thumbnail?.trim() ?? '';
    return thumb.isNotEmpty ? thumb : user.profilePicture;
  }

  factory ExploreStory.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final rawThumb = Post.normalizeMediaUrl(
      json['thumbnail']?.toString() ?? '',
    );
    return ExploreStory(
      storyId: json['story_id']?.toString() ?? '',
      thumbnail: rawThumb.isEmpty ? null : rawThumb,
      storyCount: (json['story_count'] as num?)?.toInt() ?? 1,
      hasUnseenStory: json['has_unseen_story'] == true,
      hasCloseFriendsStory: json['has_close_friends_story'] == true,
      user: userJson is Map
          ? ExploreStoryUser.fromJson(Map<String, dynamic>.from(userJson))
          : const ExploreStoryUser(id: '', username: ''),
    );
  }
}

class ExploreStoriesData {
  final ExploreStory? myStory;
  final List<ExploreStory> friends;
  final List<ExploreStory> following;

  const ExploreStoriesData({
    this.myStory,
    this.friends = const [],
    this.following = const [],
  });

  factory ExploreStoriesData.fromJson(Map<String, dynamic> json) {
    List<ExploreStory> parseList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => ExploreStory.fromJson(Map<String, dynamic>.from(e)))
          .where((s) => s.user.id.isNotEmpty)
          .toList();
    }

    final my = json['my_story'];
    return ExploreStoriesData(
      myStory: my is Map
          ? ExploreStory.fromJson(Map<String, dynamic>.from(my))
          : null,
      friends: parseList(json['friends']),
      following: parseList(json['following']),
    );
  }
}
