import 'package:gruve_app/core/parsing/safe_parsing_helpers.dart';
import 'package:gruve_app/features/message/domain/entities/user_entity.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class UserModel {
  final String userId;
  final String username;
  final String fullName;
  final String? profilePicture;
  final bool isSubscribed;

  UserModel({
    required this.userId,
    required this.username,
    required this.fullName,
    this.profilePicture,
    this.isSubscribed = true,
  });

  static bool readIsSubscribedFromJson(Map<String, dynamic> json) {
    final raw =
        json['is_subscribed'] ?? json['is_subscrribed'] ?? json['isSubscribed'];
    if (raw is bool) return raw;
    return true;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final safeJson = SafeParsingHelpers.validateAndCleanMap(
      json,
      context: 'UserModel.fromJson',
    );

    final fullName = SafeParsingHelpers.safeString(safeJson, const [
      'full_name',
      'fullName',
      'name',
    ], fallback: '');
    final username = SafeParsingHelpers.safeString(safeJson, const [
      'username',
      'user_name',
      'handle',
    ], fallback: '');
    final finalUsername = username.isNotEmpty ? username : fullName;

    return UserModel(
      userId: SafeParsingHelpers.safeString(safeJson, const [
        'user_id',
        'userId',
        'id',
        'pk',
      ], fallback: ''),
      username: finalUsername,
      fullName: fullName,
      profilePicture: SafeParsingHelpers.safeNullableString(safeJson, const [
        'profile_picture',
        'profileImage',
        'avatar',
        'photo',
      ]),
      isSubscribed: readIsSubscribedFromJson(safeJson),
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
    final safeJson = SafeParsingHelpers.validateAndCleanMap(
      json,
      context: 'PaginatedUserResponse.fromJson',
    );

    final data = SafeParsingHelpers.safeMapParse(
      safeJson['data'],
      context: 'PaginatedUserResponse.data',
    );
    if (data.isEmpty) {
      return PaginatedUserResponse(
        users: [],
        page: 1,
        hasNext: false,
        limit: 20,
      );
    }

    final resultsList = SafeParsingHelpers.safeListParse(
      data['results'],
      context: 'PaginatedUserResponse.results',
    );
    final users = <UserModel>[];

    for (int i = 0; i < resultsList.length; i++) {
      try {
        final userJson = SafeParsingHelpers.safeMapParse(
          resultsList[i],
          context: 'PaginatedUserResponse[$i]',
        );
        if (userJson.isNotEmpty) {
          final user = UserModel.fromJson(userJson);
          if (user.isSubscribed) {
            users.add(user);
          }
        }
      } catch (e) {
        AppLogger.warning(
          'PaginatedUserResponse',
          'parse_failed',
          data: {'index': i, 'error': e.toString()},
        );
      }
    }

    return PaginatedUserResponse(
      users: users,
      page: SafeParsingHelpers.safeInt(data, const ['page'], fallback: 1),
      hasNext: SafeParsingHelpers.safeBool(data, const [
        'has_next',
        'hasNext',
      ], fallback: false),
      limit: SafeParsingHelpers.safeInt(data, const ['limit'], fallback: 20),
    );
  }
}
