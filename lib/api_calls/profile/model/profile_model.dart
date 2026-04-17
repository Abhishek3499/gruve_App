import 'package:flutter/foundation.dart';

class ProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String profileImage;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.profileImage,
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

    final model = ProfileModel(
      id: id,
      fullName: fullName,
      username: username,
      profileImage: profileImage,
    );

    debugPrint(
      "[ProfileModel] created -> id: ${model.id}, fullName: ${model.fullName}, username: ${model.username}, profileImage: ${model.profileImage}",
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
}
