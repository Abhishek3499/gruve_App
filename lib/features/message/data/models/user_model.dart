import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';

class UserModel {
  final String userId;
  final String username;
  final String fullName;
  final String? profilePicture;

  UserModel({
    required this.userId,
    required this.username,
    required this.fullName,
    this.profilePicture,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fullName = json['full_name'] as String? ?? '';
    final username = (json['username'] as String?)?.isNotEmpty == true
        ? json['username'] as String
        : fullName;
    debugPrint('👤 [UserModel] Parsing user: ${json['user_id']}');
    return UserModel(
      userId: json['user_id'] as String? ?? '',
      username: username,
      fullName: fullName,
      profilePicture: json['profile_picture'] as String?,
    );
  }

  UserEntity toEntity() => UserEntity(
    userId: userId,
    username: username,
    fullName: fullName,
    profilePicture: profilePicture,
  );
}

class PaginatedUserResponse {
  final List<UserModel> users;
  final int page;
  final bool hasNext;
  final int limit;

  PaginatedUserResponse({
    required this.users,
    required this.page,
    required this.hasNext,
    required this.limit,
  });

  factory PaginatedUserResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      debugPrint('❌ [PaginatedUserResponse] No data field in response');
      return PaginatedUserResponse(
        users: [],
        page: 1,
        hasNext: false,
        limit: 20,
      );
    }

    final resultsList = data['results'] as List<dynamic>?;
    final users = resultsList?.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList() ?? [];
    
    debugPrint('📦 [PaginatedUserResponse] Parsed ${users.length} users from page ${data['page']}');
    
    return PaginatedUserResponse(
      users: users,
      page: data['page'] as int? ?? 1,
      hasNext: data['has_next'] as bool? ?? false,
      limit: data['limit'] as int? ?? 20,
    );
  }
}
