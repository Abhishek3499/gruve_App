import 'package:flutter/foundation.dart';

class ProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String profileImage;
  final bool isFollowing;
  final bool hasActiveStory;
  final int storyCount;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.profileImage,
    this.isFollowing = false,
    this.hasActiveStory = false,
    this.storyCount = 0,
  });

  /// Overlays nested `data` / `user` / `profile` fields so top-level keys resolve.
  static Map<String, dynamic> flattenUserJson(Map<String, dynamic> json) {
    final base = Map<String, dynamic>.from(json);

    void overlay(dynamic node) {
      if (node is! Map) return;
      final m = Map<String, dynamic>.from(node);
      m.forEach((k, v) {
        if (v == null) return;
        if (v is String && v.trim().isEmpty) return;
        final existing = base[k];
        final existingEmpty = existing == null ||
            (existing is String && existing.toString().trim().isEmpty);
        if (existingEmpty) {
          base[k] = v;
        }
      });
    }

    overlay(json['data']);
    overlay(json['user']);
    overlay(json['profile']);
    if (json['data'] is Map) {
      final d = Map<String, dynamic>.from(json['data'] as Map);
      overlay(d['user']);
      overlay(d['profile']);
    }

    return base;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final flat = flattenUserJson(json);
    debugPrint("[ProfileModel] fromJson (flattened keys): ${flat.keys.toList()}");
    debugPrint("[ProfileModel] Full flattened JSON: $flat");

    final fullName = _pickString(flat, const [
      'full_name',
      'fullname',
      'display_name',
      'name',
      'first_name',
    ]);

    var username = _pickString(flat, const [
      'username',
      'user_name',
      'handle',
    ]);

    if (username.isEmpty) {
      username = '';
    }

    final profileImage = _pickString(flat, const [
      'profile_picture',
      'profile_image',
      'avatar',
      'photo',
      'image',
    ]);

    final id = flat['id']?.toString() ??
        flat['user_id']?.toString() ??
        flat['pk']?.toString() ??
        "";
    final isFollowing = _pickBool(flat, const [
      'is_following',
      'is_subscribed',
      'following',
      'subscribed',
    ]);

    final parsedHasActiveStory = _pickBool(flat, const [
      'has_active_story',
      'has_story',
      'story_active',
      'has_stories',
    ]);
    final storyCount = _pickInt(flat, const [
      'story_count',
      'stories_count',
      'storyCount',
      'storiesCount',
    ]);
    final hasActiveStory = parsedHasActiveStory;

    debugPrint(
      "[ProfileModel] Checking for has_active_story in keys: ${flat.keys.toList()}",
    );
    debugPrint(
      "[ProfileModel] has_active_story value: ${flat['has_active_story']}",
    );
    debugPrint(
      "[ProfileModel] Parsed hasActiveStory flag: $parsedHasActiveStory",
    );
    debugPrint("[ProfileModel] Final hasActiveStory: $hasActiveStory");
    debugPrint("[ProfileModel] Parsed storyCount: $storyCount");

    final model = ProfileModel(
      id: id,
      fullName: fullName,
      username: username,
      profileImage: profileImage,
      isFollowing: isFollowing,
      hasActiveStory: hasActiveStory,
      storyCount: storyCount,
    );

    debugPrint(
      "[ProfileModel] created -> id: ${model.id}, fullName: ${model.fullName}, username: ${model.username}, profileImage: ${model.profileImage}, isFollowing: ${model.isFollowing}, hasActiveStory: ${model.hasActiveStory}, storyCount: ${model.storyCount}",
    );

    return model;
  }

  static String _pickString(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') {
        return s;
      }
    }
    return '';
  }

  static bool _pickBool(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final value = _toBool(map[k]);
      if (value != null) {
        return value;
      }
    }
    return false;
  }

  static bool? _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }

    return null;
  }

  static int _pickInt(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final value = _toInt(map[k]);
      if (value != null) {
        return value;
      }
    }
    return 0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim());
    }

    return null;
  }
}
