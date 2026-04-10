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

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    debugPrint("[ProfileModel] fromJson input: $json");

    final model = ProfileModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? "",
      fullName: json['full_name'] ?? "",
      username: json['username'] ?? "username_not_set",
      profileImage: json['profile_picture'] ?? "",
    );

    debugPrint(
      "[ProfileModel] created -> id: ${model.id}, fullName: ${model.fullName}, username: ${model.username}, profileImage: ${model.profileImage}",
    );

    return model;
  }
}
