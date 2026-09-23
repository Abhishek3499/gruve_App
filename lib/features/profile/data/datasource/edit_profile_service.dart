import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart'
    show TokenStorage;

import 'package:gruve_app/features/profile/data/dto/edit_profile_request.dart';
import 'package:gruve_app/features/profile/data/dto/edit_profile_response.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class EditProfileService {
  EditProfileService() : dio = AppDio.getInstance();

  final Dio dio;

  static const String _tag = 'EditProfileService';

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
      }
    }

    AppLogger.debug(
      _tag,
      'payload_built',
      data: {
        'fields': formData.fields.length,
        'files': formData.files.length,
        'hasProfilePicture':
            profilePicture != null && profilePicture.isNotEmpty,
      },
    );
    return formData;
  }

  Future<EditProfileResponse> fetchProfile() async {
    const endpoint = ApiConstants.fetchProfile;
    try {
      final token = await TokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is missing');
      }

      final headers = <String, dynamic>{'Authorization': 'Bearer $token'};

      final response = await dio.get(
        endpoint,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = _asJsonMap(response.data);
        return EditProfileResponse.fromJson(responseData);
      }

      throw Exception('Failed to fetch profile: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.warning(
        _tag,
        'api_error',
        data: {
          'method': 'GET',
          'endpoint': endpoint,
          'type': e.type.name,
          'statusCode': e.response?.statusCode,
        },
      );

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
      AppLogger.error(
        _tag,
        'unexpected_error',
        data: {'endpoint': endpoint},
        error: e,
      );
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<EditProfileResponse> updateProfile({
    required EditProfileRequest request,
  }) async {
    const endpoint = ApiConstants.updateProfile;
    try {
      final token = await TokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is missing');
      }

      final headers = <String, dynamic>{'Authorization': 'Bearer $token'};
      final requestData = await _buildUpdatePayload(request);

      final response = await dio.patch(
        endpoint,
        data: requestData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = _asJsonMap(response.data);
        final parsedResponse = EditProfileResponse.fromJson(responseData);
        return parsedResponse;
      }

      throw Exception('Failed to update profile: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.warning(
        _tag,
        'api_error',
        data: {
          'method': 'PATCH',
          'endpoint': endpoint,
          'type': e.type.name,
          'statusCode': e.response?.statusCode,
        },
      );

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
      AppLogger.error(
        _tag,
        'unexpected_error',
        data: {'endpoint': endpoint},
        error: e,
      );
      throw Exception('Failed to update profile: $e');
    }
  }
}
