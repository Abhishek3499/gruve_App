import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class UserRemoteDataSource {
  final ApiClient apiClient;
  UserRemoteDataSource(this.apiClient);

  Future<PaginatedUserResponse> fetchUsers({int page = 1, CancelToken? cancelToken}) async {
    try {
      final rawResponse = await apiClient.get(
        'user/users/?page=$page',
        cancelToken: cancelToken,
      );
      
      final response = PaginatedUserResponse.fromJson(rawResponse);
      AppLogger.d(
          '[UserRemoteDataSource] Page ${response.page} loaded: ${response.users.length} users',
        );
      
      
      return response;
    } catch (e) {
      AppLogger.d('[UserRemoteDataSource] Exception on page $page: $e');
      
      rethrow;
    }
  }
}
