import 'package:flutter/foundation.dart';

class ProfileStatsModel {
  final int subscribersCount;
  final int likesCount;
  final int videosCount;

  ProfileStatsModel({
    required this.subscribersCount,
    required this.likesCount,
    required this.videosCount,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) {
    debugPrint("[ProfileStatsModel] parsing stats from: $json");

    return ProfileStatsModel(
      subscribersCount: json['subscribers_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      videosCount: json['videos_count'] ?? 0,
    );
  }
}
