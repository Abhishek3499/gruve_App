import '../../../../core/parsing/safe_parsing_helpers.dart';
import '../../domain/entities/user_entity.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
    AppLogger.d('👤 [UserModel] 🔍 Starting user parsing');
    final safeJson = SafeParsingHelpers.validateAndCleanMap(json, context: '👤 UserModel.fromJson');
    AppLogger.d('👤 [UserModel] 🗺️ User keys: ${safeJson.keys.toList()}');
    
    final fullName = SafeParsingHelpers.safeString(safeJson, const ['full_name', 'fullName', 'name'], fallback: '');
    final username = SafeParsingHelpers.safeString(safeJson, const ['username', 'user_name', 'handle'], fallback: '');
    final finalUsername = username.isNotEmpty ? username : fullName;
    
    AppLogger.d('👤 [UserModel] 📝 Parsing user: ${safeJson['user_id']}');
    return UserModel(
      userId: SafeParsingHelpers.safeString(safeJson, const ['user_id', 'userId', 'id', 'pk'], fallback: ''),
      username: finalUsername,
      fullName: fullName,
      profilePicture: SafeParsingHelpers.safeNullableString(safeJson, const ['profile_picture', 'profileImage', 'avatar', 'photo']),
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
    AppLogger.d('📦 [PaginatedUserResponse] 🔍 Starting paginated response parsing');
    final safeJson = SafeParsingHelpers.validateAndCleanMap(json, context: '📦 PaginatedUserResponse.fromJson');
    AppLogger.d('📦 [PaginatedUserResponse] 🗺️ Response keys: ${safeJson.keys.toList()}');
    
    final data = SafeParsingHelpers.safeMapParse(safeJson['data'], context: '📦 PaginatedUserResponse.data');
    if (data.isEmpty) {
      AppLogger.d('❌ [PaginatedUserResponse] 🚫 No data field in response');
      return PaginatedUserResponse(
        users: [],
        page: 1,
        hasNext: false,
        limit: 20,
      );
    }

    final resultsList = SafeParsingHelpers.safeListParse(data['results'], context: '📦 PaginatedUserResponse.results');
    final users = <UserModel>[];
    
    AppLogger.d('📦 [PaginatedUserResponse] 📝 Processing ${resultsList.length} users');
    for (int i = 0; i < resultsList.length; i++) {
      try {
        final userJson = SafeParsingHelpers.safeMapParse(resultsList[i], context: '📦 PaginatedUserResponse[$i]');
        if (userJson.isNotEmpty) {
          final user = UserModel.fromJson(userJson);
          users.add(user);
          AppLogger.d('✅ [PaginatedUserResponse] ✨ Successfully parsed user at index $i');
        }
      } catch (e) {
        AppLogger.d('💥 [PaginatedUserResponse] ❌ Failed to parse user at index $i: $e');
      }
    }
    
    AppLogger.d('📦 [PaginatedUserResponse] 🏆 Parsed ${users.length}/${resultsList.length} users from page ${data['page']}');
    
    return PaginatedUserResponse(
      users: users,
      page: SafeParsingHelpers.safeInt(data, const ['page'], fallback: 1),
      hasNext: SafeParsingHelpers.safeBool(data, const ['has_next', 'hasNext'], fallback: false),
      limit: SafeParsingHelpers.safeInt(data, const ['limit'], fallback: 20),
    );
  }
}
