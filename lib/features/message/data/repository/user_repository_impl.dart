import 'package:dio/dio.dart';
import '../../domain/repository/user_repository.dart';
import '../datasource/user_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource dataSource;
  UserRepositoryImpl(this.dataSource);

  @override
  Future<List<UserEntity>> getUsers({CancelToken? cancelToken}) async {
    try {
      final response = await dataSource.fetchUsers(page: 1, cancelToken: cancelToken);
      AppLogger.d('🧠 [UserRepositoryImpl] Initial load: ${response.users.length} users');
      return response.users.map((m) => m.toEntity()).toList();
    } catch (e) {
      AppLogger.d('💥 [UserRepositoryImpl] Error in initial load: $e');
      rethrow;
    }
  }

  Future<PaginatedUserResponse> fetchUsersPaginated({
    int page = 1,
    CancelToken? cancelToken,
    bool skipCache = false,
  }) async {
    try {
      AppLogger.d('🧠 [UserRepositoryImpl] Fetching page $page');
      final response = await dataSource.fetchUsers(
        page: page,
        cancelToken: cancelToken,
        skipCache: skipCache,
      );
      AppLogger.d('✅ [UserRepositoryImpl] Page $page fetched: ${response.users.length} users');
      return response;
    } catch (e) {
      AppLogger.d('💥 [UserRepositoryImpl] Error fetching page $page: $e');
      rethrow;
    }
  }
}
