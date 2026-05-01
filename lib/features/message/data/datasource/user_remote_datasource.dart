import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserRemoteDataSource {
  final ApiClient apiClient;
  UserRemoteDataSource(this.apiClient);

  Future<PaginatedUserResponse> fetchUsers({int page = 1}) async {
    try {
      debugPrint('🌐 [UserRemoteDataSource] Hitting API: user/users/?page=$page');
      final rawResponse = await apiClient.get('user/users/?page=$page');
      debugPrint('📦 [UserRemoteDataSource] Raw response: $rawResponse');
      
      final response = PaginatedUserResponse.fromJson(rawResponse);
      debugPrint('📊 [UserRemoteDataSource] Page ${response.page} loaded: ${response.users.length} users');
      debugPrint('➡️ [UserRemoteDataSource] Has next: ${response.hasNext}');
      
      return response;
    } catch (e) {
      debugPrint('💥 [UserRemoteDataSource] Exception on page $page: $e');
      rethrow;
    }
  }
}
