import 'package:gruve_app/core/parsing/safe_parsing_helpers.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    AppLogger.d(
      "[ProfileModel] fromJson (flattened keys): ${flat.keys.toList()}",
    );
    AppLogger.d("[ProfileModel] Full flattened JSON: $flat");

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

    final storyCount = SafeParsingHelpers.safeInt(flat, const [
      'story_count',
      'stories_count',
      'storyCount',
      'storiesCount',
    ], fallback: 0);

    final hasActiveStory = parsedHasActiveStory;

    AppLogger.d(
      "[ProfileModel] Checking for has_active_story in keys: ${flat.keys.toList()}",
    );
    AppLogger.d(
      "[ProfileModel] has_active_story value: ${flat['has_active_story']}",
    );
    AppLogger.d(
      "[ProfileModel] Parsed hasActiveStory flag: $parsedHasActiveStory",
    );
    AppLogger.d("[ProfileModel] Final hasActiveStory: $hasActiveStory");
    AppLogger.d("[ProfileModel] Parsed storyCount: $storyCount");

    final model = ProfileModel(
      id: id,
      fullName: fullName,
      username: username,
      profileImage: profileImage,
      isFollowing: isFollowing,
      hasActiveStory: hasActiveStory,
      storyCount: storyCount,
    );

    AppLogger.d(
      "[ProfileModel] created -> id: ${model.id}, fullName: ${model.fullName}, username: ${model.username}, profileImage: ${model.profileImage}, isFollowing: ${model.isFollowing}, hasActiveStory: ${model.hasActiveStory}, storyCount: ${model.storyCount}",
    );

    return model;
  }
}
