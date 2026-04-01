import 'package:flutter/foundation.dart';

class ProfileModel {
  final String fullName;
  final String username;
  final String profileImage;

  ProfileModel({
    required this.fullName,
    required this.username,
    required this.profileImage,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    debugPrint("[ProfileModel] fromJson input: $json");

    final model = ProfileModel(
      fullName: json['full_name'] ?? "",
      username: json['username'] ?? "username_not_set",
      profileImage: json['profile_picture'] ?? "",
    );

    debugPrint(
      "[ProfileModel] created -> fullName: ${model.fullName}, username: ${model.username}, profileImage: ${model.profileImage}",
    );

    return model;
  }
}
