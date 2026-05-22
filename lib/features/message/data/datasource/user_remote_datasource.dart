import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserRemoteDataSource {
  final ApiClient apiClient;
  UserRemoteDataSource(this.apiClient);

  Future<PaginatedUserResponse> fetchUsers({int page = 1}) async {
    try {
      final rawResponse = await apiClient.get('user/users/?page=$page');
      
      final response = PaginatedUserResponse.fromJson(rawResponse);
      if (kDebugMode) {
        debugPrint(
          '[UserRemoteDataSource] Page ${response.page} loaded: ${response.users.length} users',
        );
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserRemoteDataSource] Exception on page $page: $e');
      }
      rethrow;
    }
  }
}
