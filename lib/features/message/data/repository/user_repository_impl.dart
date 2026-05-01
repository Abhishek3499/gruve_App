import 'package:flutter/foundation.dart';
import '../../domain/repository/user_repository.dart';
import '../datasource/user_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource dataSource;
  UserRepositoryImpl(this.dataSource);

  @override
  Future<List<UserEntity>> getUsers() async {
    try {
      final response = await dataSource.fetchUsers(page: 1);
      debugPrint('🧠 [UserRepositoryImpl] Initial load: ${response.users.length} users');
      return response.users.map((m) => m.toEntity()).toList();
    } catch (e) {
      debugPrint('💥 [UserRepositoryImpl] Error in initial load: $e');
      rethrow;
    }
  }

  Future<PaginatedUserResponse> fetchUsersPaginated({int page = 1}) async {
    try {
      debugPrint('🧠 [UserRepositoryImpl] Fetching page $page');
      final response = await dataSource.fetchUsers(page: page);
      debugPrint('✅ [UserRepositoryImpl] Page $page fetched: ${response.users.length} users');
      return response;
    } catch (e) {
      debugPrint('💥 [UserRepositoryImpl] Error fetching page $page: $e');
      rethrow;
    }
  }
}
