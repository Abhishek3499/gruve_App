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
    debugPrint("[ProfileStatsModel] parsing stats from: $json");

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
      ],
    );
    final likesCount = _findCount(
      json,
      const [
        'likes_count',
        'like_count',
        'likes',
        'total_likes',
      ],
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
      ],
    );

    debugPrint(
      "[ProfileStatsModel] resolved -> subscribers: $subscribersCount, likes: $likesCount, videos: $videosCount",
    );

    return ProfileStatsModel(
      subscribersCount: subscribersCount,
      likesCount: likesCount,
      videosCount: videosCount,
    );
  }

  static int _findCount(dynamic source, List<String> keys) {
    final normalizedKeys = keys.map(_normalizeKey).toSet();
    final visited = <Object>{};

    int? search(dynamic value) {
      if (value == null) {
        return null;
      }

      if (value is Map) {
        if (!visited.add(value)) {
          return null;
        }

        final map = Map<String, dynamic>.from(value);

        for (final entry in map.entries) {
          final normalizedKey = _normalizeKey(entry.key);
          if (normalizedKeys.contains(normalizedKey)) {
            final parsed = _toCount(entry.value);
            if (parsed != null) {
              debugPrint(
                "[ProfileStatsModel] matched key `${entry.key}` with value `${entry.value}` -> $parsed",
              );
              return parsed;
            }
          }
        }

        for (final entry in map.entries) {
          final parsed = search(entry.value);
          if (parsed != null) {
            return parsed;
          }
        }

        return null;
      }

      if (value is List) {
        for (final item in value) {
          final parsed = search(item);
          if (parsed != null) {
            return parsed;
          }
        }
      }

      return null;
    }

    return search(source) ?? 0;
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
