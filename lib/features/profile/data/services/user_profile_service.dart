import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import '../models/user_profile_model.dart';

class UserProfileService {
  final Dio _dio;

  UserProfileService({Dio? dio}) : _dio = dio ?? AppDio.create();

  Future<UserProfile> getUserProfile(String userId) async {
    debugPrint('🌐 [UserProfileService] Fetching profile for userId: $userId');
    
    final endpoint = 'user/profile/$userId/';
    debugPrint('🌐 [UserProfileService] URL: /$endpoint');

    try {
      final response = await _dio.get(endpoint);
      
      debugPrint('📡 [UserProfileService] Response status: ${response.statusCode}');
      debugPrint('📄 [UserProfileService] Response body: ${response.data}');

      if (response.statusCode == 200) {
        final userProfile = UserProfile.fromJson(response.data['data'] ?? response.data);
        debugPrint('✅ [UserProfileService] Parsed model: ${userProfile.username}');
        return userProfile;
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ [UserProfileService] DioException: ${e.message}');
      debugPrint('❌ [UserProfileService] Status code: ${e.response?.statusCode}');
      
      if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Validation error');
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        throw Exception('Network timeout. Please check your connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection. Please check your network.');
      } else {
        throw Exception('Failed to load profile: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ [UserProfileService] Unexpected error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
