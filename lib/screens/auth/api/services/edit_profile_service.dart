import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart' show TokenStorage;
import '../models/edit_profile_request.dart';
import '../models/edit_profile_response.dart';

class EditProfileService {
  EditProfileService()
    : dio = Dio(
        BaseOptions(
          baseUrl: _normalizeBase(dotenv.env['BASE_URL'] ?? ''),
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  final Dio dio;

  static String _normalizeBase(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    return t.endsWith('/') ? t : '$t/';
  }

  static Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw FormatException(
      'Edit profile: expected JSON object, got ${data.runtimeType}',
    );
  }

  /// Fetch user profile data from /user/edit_profile endpoint
  Future<EditProfileResponse> fetchProfile() async {
    try {
      final token = await TokenStorage.getAccessToken();

      debugPrint("=== FETCH PROFILE REQUEST ===");
      debugPrint(
        "TOKEN: ${token == null || token.isEmpty ? "missing" : "present"}",
      );

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is missing');
      }

      const endpoint = "user/edit_profile/";
      final headers = <String, dynamic>{"Authorization": "Bearer $token"};

      debugPrint("=== FETCH PROFILE REQUEST DETAILS ===");
      debugPrint("URL: ${dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: GET");
      debugPrint("HEADERS: $headers");

      final response = await dio.get(
        endpoint,
        options: Options(headers: headers),
      );

      debugPrint("=== FETCH PROFILE RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE DATA: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        final responseData = _asJsonMap(response.data);
        return EditProfileResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint("=== FETCH PROFILE DIO ERROR ===");
      debugPrint("ERROR TYPE: ${e.type}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      
      String errorMessage = 'Network error occurred';
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'Access denied. You do not have permission to edit this profile.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Profile not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint("=== FETCH PROFILE GENERAL ERROR ===");
      debugPrint("ERROR: $e");
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Update user profile data to /user/edit_profile endpoint
  Future<EditProfileResponse> updateProfile({
    required EditProfileRequest request,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();

      debugPrint("=== UPDATE PROFILE REQUEST ===");
      debugPrint(
        "TOKEN: ${token == null || token.isEmpty ? "missing" : "present"}",
      );

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is missing');
      }

      const endpoint = "user/edit_profile/";
      final headers = <String, dynamic>{"Authorization": "Bearer $token"};
      final requestData = request.toJson();

      debugPrint("=== UPDATE PROFILE REQUEST DETAILS ===");
      debugPrint("URL: ${dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: PATCH");
      debugPrint("HEADERS: $headers");
      debugPrint("REQUEST DATA: $requestData");

      // Debug all request fields
      debugPrint("=== UPDATE PROFILE DEBUG INFO ===");
      debugPrint("Request object fields:");
      debugPrint("  - fullName: ${request.fullName}");
      debugPrint("  - username: ${request.username}");
      debugPrint("  - bio: ${request.bio}");
      debugPrint("  - profilePicture: ${request.profilePicture}");

      final response = await dio.patch(
        endpoint,
        data: requestData,
        options: Options(headers: headers),
      );

      debugPrint("=== UPDATE PROFILE RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE DATA: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        final responseData = _asJsonMap(response.data);
        return EditProfileResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint("=== UPDATE PROFILE DIO ERROR ===");
      debugPrint("ERROR TYPE: ${e.type}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      
      String errorMessage = 'Network error occurred';
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid data. Please check your input.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'Access denied. You do not have permission to edit this profile.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Profile not found.';
      } else if (e.response?.statusCode == 409) {
        errorMessage = 'Username already exists.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint("=== UPDATE PROFILE GENERAL ERROR ===");
      debugPrint("ERROR: $e");
      throw Exception('Failed to update profile: $e');
    }
  }
}
