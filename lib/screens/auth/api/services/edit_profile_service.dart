import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/token_storage.dart' show TokenStorage;

import '../models/edit_profile_request.dart';
import '../models/edit_profile_response.dart';

class EditProfileService {
  EditProfileService()
    : dio = AppDio.create(
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      );

  final Dio dio;

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

  static bool _isLocalFilePath(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;

    return !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://') &&
        !trimmed.startsWith('assets/');
  }

  static String? _extractErrorMessage(dynamic data) {
    if (data is! Map) return null;

    final map = Map<String, dynamic>.from(data);
    final error = map['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }

    for (final key in ['message', 'detail']) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  Future<dynamic> _buildUpdatePayload(EditProfileRequest request) async {
    debugPrint(
      '[EditProfileService] Always using FormData for profile update...',
    );
    final baseData = request.toJson();
    final formData = FormData.fromMap(
      baseData.map((key, value) => MapEntry(key, value.toString())),
    );
    final profilePicture = request.profile_picture?.trim();

    if (profilePicture != null && profilePicture.isNotEmpty) {
      if (_isLocalFilePath(profilePicture)) {
        final file = File(profilePicture);
        if (!await file.exists()) {
          throw Exception(
            'Selected profile image "$profilePicture" was not found.',
          );
        }
        formData.files.add(
          MapEntry(
            'profile_picture',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
        debugPrint('[EditProfileService] Added local file: ${file.path}');
      } else {
        // Remote image URL, add as string field
        // Remote images handled by FormData.fromMap(baseData)
        debugPrint(
          '[EditProfileService] Added remote image URL: $profilePicture',
        );
      }
    } else {
      debugPrint('[EditProfileService] No profile_picture provided, omitted');
    }

    debugPrint(
      '[EditProfileService] FormData: ${formData.fields.length} fields, ${formData.files.length} files',
    );
    return formData;
  }

  Future<EditProfileResponse> fetchProfile() async {
    try {
      final token = await TokenStorage.getAccessToken();

      debugPrint('=== FETCH PROFILE REQUEST ===');
      debugPrint(
        'TOKEN: ${token == null || token.isEmpty ? "missing" : "present"}',
      );

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is missing');
      }

      const endpoint = 'user/edit_profile';
      final headers = <String, dynamic>{'Authorization': 'Bearer $token'};

      debugPrint('=== FETCH PROFILE REQUEST DETAILS ===');
      debugPrint('URL: ${dio.options.baseUrl}$endpoint');
      debugPrint('METHOD: GET');
      debugPrint('HEADERS: $headers');

      final response = await dio.get(
        endpoint,
        options: Options(headers: headers),
      );

      debugPrint('=== FETCH PROFILE RESPONSE ===');
      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE DATA: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = _asJsonMap(response.data);
        return EditProfileResponse.fromJson(responseData);
      }

      throw Exception('Failed to fetch profile: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('=== FETCH PROFILE DIO ERROR ===');
      debugPrint('ERROR TYPE: ${e.type}');
      debugPrint('ERROR MESSAGE: ${e.message}');
      debugPrint('STATUS CODE: ${e.response?.statusCode}');

      String errorMessage = 'Network error occurred';
      final backendMessage = _extractErrorMessage(e.response?.data);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (backendMessage != null) {
        errorMessage = backendMessage;
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 403) {
        errorMessage =
            'Access denied. You do not have permission to edit this profile.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Profile not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('=== FETCH PROFILE GENERAL ERROR ===');
      debugPrint('ERROR: $e');
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<EditProfileResponse> updateProfile({
    required EditProfileRequest request,
  }) async {
    debugPrint('[EditProfileService] Starting updateProfile...');
    debugPrint(
      '[EditProfileService] Service initialized with base URL: ${dio.options.baseUrl}',
    );

    try {
      debugPrint('[EditProfileService] Getting access token...');
      final token = await TokenStorage.getAccessToken();
      final tokenPreview = token == null || token.isEmpty
          ? 'null_or_empty'
          : '${token.substring(0, token.length > 12 ? 12 : token.length)}...';

      debugPrint('[EditProfileService] Token status: $tokenPreview');

      if (token == null || token.isEmpty) {
        debugPrint('[EditProfileService] Authentication token is missing');
        throw Exception('Authentication token is missing');
      }

      const endpoint = 'user/edit_profile/';
      final headers = <String, dynamic>{'Authorization': 'Bearer $token'};
      final requestData = await _buildUpdatePayload(request);
      final isMultipart = true; // Always FormData now

      debugPrint('[EditProfileService] PATCH $endpoint');
      debugPrint('[EditProfileService] Headers: $headers');
      debugPrint('[EditProfileService] Request object analysis:');
      debugPrint(
        "  fullname='${request.fullname}' length=${request.fullname.length}",
      );
      debugPrint(
        "  username='${request.username}' length=${request.username.length}",
      );
      debugPrint(
        "  bio='${request.bio ?? 'null'}' ${request.bio != null ? 'length=${request.bio!.length}' : ''}",
      );
      debugPrint(
        "  profile_picture='${request.profile_picture ?? 'null'}' isFile=${_isLocalFilePath(request.profile_picture)}",
      );

      if (requestData is FormData) {
        debugPrint(
          '[EditProfileService] Request fields: ${requestData.fields}',
        );
        debugPrint(
          '[EditProfileService] Request files: ${requestData.files.map((file) => '${file.key}: ${file.value.filename}').toList()}',
        );
      } else {
        debugPrint('[EditProfileService] Request data: $requestData');
      }

      debugPrint('[EditProfileService] Making API call...');

      final response = await dio.patch(
        endpoint,
        data: requestData,
        options: Options(headers: headers),
      );

      debugPrint('[EditProfileService] Response received');
      debugPrint('[EditProfileService] Status code: ${response.statusCode}');
      debugPrint('[EditProfileService] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = _asJsonMap(response.data);
        final parsedResponse = EditProfileResponse.fromJson(responseData);
        debugPrint(
          '[EditProfileService] Profile updated successfully: ${parsedResponse.message}',
        );
        return parsedResponse;
      }

      throw Exception('Failed to update profile: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('[EditProfileService] DioException caught');
      debugPrint('[EditProfileService] Error type: ${e.type}');
      debugPrint('[EditProfileService] Error message: ${e.message}');
      debugPrint('[EditProfileService] Status code: ${e.response?.statusCode}');
      if (e.response?.data != null) {
        debugPrint(
          '[EditProfileService] Backend error response: ${e.response?.data}',
        );
      }

      String errorMessage = 'Network error occurred';
      final backendMessage = _extractErrorMessage(e.response?.data);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (backendMessage != null) {
        errorMessage = backendMessage;
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 403) {
        errorMessage =
            'Access denied. You do not have permission to edit this profile.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Profile not found.';
      } else if (e.response?.statusCode == 409) {
        errorMessage = 'Username already exists.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.response?.statusCode != null) {
        errorMessage = 'Server returned error: ${e.response?.statusCode}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('[EditProfileService] General exception caught: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
}
