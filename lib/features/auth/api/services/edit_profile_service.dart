import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/token_storage.dart' show TokenStorage;

import '../models/edit_profile_request.dart';
import '../models/edit_profile_response.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class EditProfileService {
  EditProfileService()
    : dio = AppDio.getInstance();

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
    AppLogger.d(
      '[EditProfileService] Always using FormData for profile update...',
    );
    final baseData = request.toJson();
    final formData = FormData.fromMap(
      baseData.map((key, value) => MapEntry(key, value.toString())),
    );
    final profilePicture = request.profilePicture?.trim();

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
        AppLogger.d('[EditProfileService] Added local file: ${file.path}');
      } else {
        // Remote image URL, add as string field
        // Remote images handled by FormData.fromMap(baseData)
        AppLogger.d(
          '[EditProfileService] Added remote image URL: $profilePicture',
        );
      }
    } else {
      AppLogger.d('[EditProfileService] No profile_picture provided, omitted');
    }

    AppLogger.d(
      '[EditProfileService] FormData: ${formData.fields.length} fields, ${formData.files.length} files',
    );
    return formData;
  }

  Future<EditProfileResponse> fetchProfile() async {
    try {
      final token = await TokenStorage.getAccessToken();

      AppLogger.d('=== FETCH PROFILE REQUEST ===');
      AppLogger.d(
        'TOKEN: ${token == null || token.isEmpty ? "missing" : "present"}',
      );

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is missing');
      }

      const endpoint = ApiConstants.fetchProfile;
      final headers = <String, dynamic>{'Authorization': 'Bearer $token'};

      AppLogger.d('=== FETCH PROFILE REQUEST DETAILS ===');
      AppLogger.d('URL: ${dio.options.baseUrl}$endpoint');
      AppLogger.d('METHOD: GET');
      AppLogger.d(
        "HEADERS: authorization=${headers.containsKey('Authorization')}",
      );

      final response = await dio.get(
        endpoint,
        options: Options(headers: headers),
      );

      AppLogger.d('=== FETCH PROFILE RESPONSE ===');
      AppLogger.d('STATUS CODE: ${response.statusCode}');
      AppLogger.d('RESPONSE DATA TYPE: ${response.data.runtimeType}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = _asJsonMap(response.data);
        return EditProfileResponse.fromJson(responseData);
      }

      throw Exception('Failed to fetch profile: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.d('=== FETCH PROFILE DIO ERROR ===');
      AppLogger.d('ERROR TYPE: ${e.type}');
      AppLogger.d('ERROR MESSAGE: ${e.message}');
      AppLogger.d('STATUS CODE: ${e.response?.statusCode}');

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
      AppLogger.d('=== FETCH PROFILE GENERAL ERROR ===');
      AppLogger.d('ERROR: $e');
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<EditProfileResponse> updateProfile({
    required EditProfileRequest request,
  }) async {
    AppLogger.d('[EditProfileService] Starting updateProfile...');
    AppLogger.d(
      '[EditProfileService] Service initialized with base URL: ${dio.options.baseUrl}',
    );

    try {
      AppLogger.d('[EditProfileService] Getting access token...');
      final token = await TokenStorage.getAccessToken();
      final tokenPreview = token == null || token.isEmpty
          ? 'null_or_empty'
          : '${token.substring(0, token.length > 12 ? 12 : token.length)}...';

      AppLogger.d('[EditProfileService] Token status: $tokenPreview');

      if (token == null || token.isEmpty) {
        AppLogger.d('[EditProfileService] Authentication token is missing');
        throw Exception('Authentication token is missing');
      }

      const endpoint = ApiConstants.updateProfile;
      final headers = <String, dynamic>{'Authorization': 'Bearer $token'};
      final requestData = await _buildUpdatePayload(request);

      AppLogger.d('[EditProfileService] PATCH $endpoint');
      AppLogger.d('[EditProfileService] Headers: $headers');
      AppLogger.d('[EditProfileService] Request object analysis:');
      AppLogger.d(
        "  fullname='${request.fullname}' length=${request.fullname.length}",
      );
      AppLogger.d(
        "  username='${request.username}' length=${request.username.length}",
      );
      AppLogger.d(
        "  bio='${request.bio ?? 'null'}' ${request.bio != null ? 'length=${request.bio!.length}' : ''}",
      );
      AppLogger.d(
        "  profile_picture='${request.profilePicture ?? 'null'}' isFile=${_isLocalFilePath(request.profilePicture)}",
      );

      if (requestData is FormData) {
        AppLogger.d(
          '[EditProfileService] Request fields: ${requestData.fields}',
        );
        AppLogger.d(
          '[EditProfileService] Request files: ${requestData.files.map((file) => '${file.key}: ${file.value.filename}').toList()}',
        );
      } else {
        AppLogger.d('[EditProfileService] Request data: $requestData');
      }

      AppLogger.d('[EditProfileService] Making API call...');

      final response = await dio.patch(
        endpoint,
        data: requestData,
        options: Options(headers: headers),
      );

      AppLogger.d('[EditProfileService] Response received');
      AppLogger.d('[EditProfileService] Status code: ${response.statusCode}');
      AppLogger.d('[EditProfileService] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = _asJsonMap(response.data);
        final parsedResponse = EditProfileResponse.fromJson(responseData);
        AppLogger.d(
          '[EditProfileService] Profile updated successfully: ${parsedResponse.message}',
        );
        return parsedResponse;
      }

      throw Exception('Failed to update profile: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.d('[EditProfileService] DioException caught');
      AppLogger.d('[EditProfileService] Error type: ${e.type}');
      AppLogger.d('[EditProfileService] Error message: ${e.message}');
      AppLogger.d('[EditProfileService] Status code: ${e.response?.statusCode}');
      if (e.response?.data != null) {
        AppLogger.d(
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
      AppLogger.d('[EditProfileService] General exception caught: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
}
