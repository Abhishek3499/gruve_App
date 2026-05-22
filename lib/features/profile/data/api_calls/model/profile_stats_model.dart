import 'package:flutter/foundation.dart';

class ProfileStatsModel {
  final int subscribersCount;
  final int likesCount;
  final int videosCount;

  const ProfileStatsModel({
    required this.subscribersCount,
    required this.likesCount,
    required this.videosCount,
  });

  const ProfileStatsModel.empty()
      : subscribersCount = 0,
        likesCount = 0,
        videosCount = 0;

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) {
    debugPrint("🔍 [ProfileStatsModel] parsing stats from: $json");
    debugPrint("🔍 [ProfileStatsModel] JSON KEYS: ${json.keys.toList()}");

    final subscribersCount = _findCount(
      json,
      const [
        'subscribers_count',
        'subscriber_count',
        'subscribers',
        'subscriber',
        'subscribersCount',
        'subscriberCount',
        'followers_count',
        'follower_count',
        'followers',
        'followersCount',
        'followerCount',
        'total_subscribers',
        'total_followers',
        'fans_count',
        'fan_count',
        'data.user.stats.subscribers_count',
        'data.user.stats.subscriber_count',
        'data.user.stats.subscribers',
        'data.user.stats.subscriber',
        'data.user.stats.followers_count',
        'data.user.stats.follower_count',
        'data.user.stats.followers',
        'data.user.stats.follower',
        'user.stats.subscribers_count',
        'user.stats.subscriber_count',
        'user.stats.subscribers',
        'user.stats.subscriber',
        'user.stats.followers_count',
        'user.stats.follower_count',
        'user.stats.followers',
        'user.stats.follower',
      ],
      'subscribers',
    );
    final likesCount = _findCount(
      json,
      const [
        'likes_count',
        'like_count',
        'likes',
        'total_likes',
        'data.user.stats.likes_count',
        'data.user.stats.like_count',
        'data.user.stats.likes',
        'data.user.stats.total_likes',
        'user.stats.likes_count',
        'user.stats.like_count',
        'user.stats.likes',
        'user.stats.total_likes',
      ],
      'likes',
    );
    final videosCount = _findCount(
      json,
      const [
        'videos_count',
        'video_count',
        'videos',
        'posts_count',
        'post_count',
        'posts',
        'data.user.stats.videos_count',
        'data.user.stats.video_count',
        'data.user.stats.videos',
        'data.user.stats.posts_count',
        'data.user.stats.post_count',
        'data.user.stats.posts',
        'user.stats.videos_count',
        'user.stats.video_count',
        'user.stats.videos',
        'user.stats.posts_count',
        'user.stats.post_count',
        'user.stats.posts',
      ],
      'videos',
    );

    debugPrint(
      "🔍 [ProfileStatsModel] FINAL RESULT -> subscribers: $subscribersCount, likes: $likesCount, videos: $videosCount",
    );

    return ProfileStatsModel(
      subscribersCount: subscribersCount,
      likesCount: likesCount,
      videosCount: videosCount,
    );
  }

  static int _findCount(dynamic source, List<String> keys, String fieldName) {
    debugPrint("🔍 [ProfileStatsModel] Searching for $fieldName count in ${keys.length} possible keys");
    final normalizedKeys = keys.map(_normalizeKey).toSet();
    final visited = <Object>{};

    int? search(dynamic value, [String path = '']) {
      if (value == null) {
        return null;
      }

      if (value is Map) {
        if (!visited.add(value)) {
          return null;
        }

        final map = Map<String, dynamic>.from(value);
        final currentPath = path.isEmpty ? 'root' : path;
        debugPrint("🔍 [ProfileStatsModel] Searching in map at $currentPath with keys: ${map.keys.toList()}");

        for (final entry in map.entries) {
          final normalizedKey = _normalizeKey(entry.key);
          if (normalizedKeys.contains(normalizedKey)) {
            final parsed = _toCount(entry.value);
            if (parsed != null) {
              debugPrint(
                "✅ [ProfileStatsModel] $fieldName MATCHED key `${entry.key}` at $currentPath with value `${entry.value}` -> $parsed",
              );
              return parsed;
            } else {
              debugPrint("⚠️ [ProfileStatsModel] $fieldName found key `${entry.key}` but couldn't parse value: ${entry.value}");
            }
          }
        }

        for (final entry in map.entries) {
          final nestedPath = path.isEmpty ? entry.key : '$path.${entry.key}';
          final parsed = search(entry.value, nestedPath);
          if (parsed != null) {
            return parsed;
          }
        }

        return null;
      }

      if (value is List) {
        debugPrint("🔍 [ProfileStatsModel] Searching in list at $path with ${value.length} items");
        for (int i = 0; i < value.length; i++) {
          final item = value[i];
          final nestedPath = '$path[$i]';
          final parsed = search(item, nestedPath);
          if (parsed != null) {
            return parsed;
          }
        }
      }

      return null;
    }

    final result = search(source) ?? 0;
    debugPrint("🔍 [ProfileStatsModel] $fieldName final result: $result");
    return result;
  }

  static int? _toCount(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value.trim());
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is List) {
      return value.length;
    }

    if (value is Set) {
      return value.length;
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final entry in map.entries) {
        final normalizedKey = _normalizeKey(entry.key);
        if (normalizedKey == 'count' ||
            normalizedKey == 'total' ||
            normalizedKey == 'length' ||
            normalizedKey.endsWith('count')) {
          final nested = _toCount(entry.value);
          if (nested != null) {
            return nested;
          }
        }
      }
    }

    return null;
  }

  static String _normalizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfileStatsModel &&
        other.subscribersCount == subscribersCount &&
        other.likesCount == likesCount &&
        other.videosCount == videosCount;
  }

  @override
  int get hashCode =>
      subscribersCount.hashCode ^ likesCount.hashCode ^ videosCount.hashCode;
}
