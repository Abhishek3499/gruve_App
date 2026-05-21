import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/token_storage.dart' show TokenStorage;
import 'package:gruve_app/screens/auth/core/auth_api_exception.dart';
import 'package:gruve_app/screens/auth/core/auth_api_logger.dart';
import 'package:image_picker/image_picker.dart';
import '../models/complete_profile_request.dart';
import '../models/complete_profile_response.dart';

class CompleteProfileService {
  CompleteProfileService()
    : dio = AppDio.create(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
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
      'Complete profile: expected JSON object, got ${data.runtimeType}',
    );
  }

  Future<CompleteProfileResponse> completeProfile({
    required CompleteProfileRequest request,
    String? file,
    XFile? image,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();

      debugPrint(
        "Complete profile token: ${token == null || token.isEmpty ? "missing" : "present"}",
      );

      if (token == null || token.isEmpty) {
        throw Exception(
          'Not signed in. Finish OTP verification first, then try again.',
        );
      }

      final formMap = <String, dynamic>{"username": request.username};
      final upload = await _buildUploadFile(image: image, file: file);
      if (upload != null) {
        formMap["file"] = upload;
      }

      final formData = FormData.fromMap(formMap);

      const endpoint = "auth/complete-profile/";
      final headers = <String, dynamic>{"Authorization": "Bearer $token"};

      AuthApiLogger.request(
        'CompleteProfile',
        dio: dio,
        endpoint: endpoint,
        method: 'POST',
        body: {'username': request.username, 'hasFile': upload != null},
      );

      final response = await dio.post(
        endpoint,
        data: formData,
        options: Options(headers: headers),
      );

      AuthApiLogger.response('CompleteProfile', response);

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('Unexpected status $status');
      }

      final map = _asJsonMap(response.data);
      final result = CompleteProfileResponse.fromJson(map);

      if (result.success) {
        return result;
      }

      final msg = result.message.trim().isEmpty
          ? 'Could not complete profile. Check username or image and try again.'
          : result.message;
      throw Exception(msg);
    } on DioException catch (e) {
      AuthApiLogger.error('CompleteProfile', e);
      final data = e.response?.data;
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        for (final key in ['message', 'detail', 'error']) {
          final v = m[key];
          if (v is String && v.trim().isNotEmpty) {
            throw Exception(v.trim());
          }
        }
      }
      throw Exception(AuthApiException.extractMessage(e));
    } catch (e) {
      debugPrint("Complete profile failed: $e");
      rethrow;
    }
  }

  Future<MultipartFile?> _buildUploadFile({XFile? image, String? file}) async {
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return null;

      return MultipartFile.fromBytes(
        bytes,
        filename: image.name.isNotEmpty ? image.name : 'profile_image.jpg',
      );
    }

    final path = file?.trim();
    if (path == null || path.isEmpty) return null;

    return MultipartFile.fromFile(path);
  }
}
