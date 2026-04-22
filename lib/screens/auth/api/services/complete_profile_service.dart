import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart' show TokenStorage;
import '../models/complete_profile_request.dart';
import '../models/complete_profile_response.dart';

class CompleteProfileService {
  CompleteProfileService()
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
      'Complete profile: expected JSON object, got ${data.runtimeType}',
    );
  }

  Future<CompleteProfileResponse> completeProfile({
    required CompleteProfileRequest request,
    String? file,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();

      debugPrint("=== COMPLETE PROFILE REQUEST ===");
      debugPrint(
        "TOKEN: ${token == null || token.isEmpty ? "missing" : "present"}",
      );

      if (token == null || token.isEmpty) {
        throw Exception(
          'Not signed in. Finish OTP verification first, then try again.',
        );
      }

      final formData = FormData.fromMap({
        "username": request.username,

        if (file != null && file.trim().isNotEmpty)
          "file": await MultipartFile.fromFile(file.trim()),
      });

      const endpoint = "auth/complete-profile/";
      final headers = <String, dynamic>{"Authorization": "Bearer $token"};

      debugPrint("=== COMPLETE PROFILE REQUEST DETAILS ===");
      debugPrint("URL: ${dio.options.baseUrl}$endpoint");
      debugPrint("METHOD: POST");
      debugPrint("HEADERS: $headers");
      debugPrint("FORM DATA FIELDS: ${formData.fields}");
      debugPrint("FORM DATA FILES: ${formData.files.map((f) => f.key)}");

      // Debug all request fields
      debugPrint("=== COMPLETE PROFILE DEBUG INFO ===");
      debugPrint("Request object fields:");
      debugPrint("  - username: ${request.username}");

      debugPrint("  - file: ${file ?? 'null'}");

      debugPrint("Form data being sent:");
      final fieldList = <String>[];
      for (int i = 0; i < formData.fields.length; i++) {
        final entry = formData.fields[i];
        fieldList.add('${entry.key}: ${entry.value}');
      }
      debugPrint("  - All form fields: $fieldList");
      debugPrint(
        "  - All form files: ${formData.files.map((f) => '${f.key}: ${f.value.filename}').toList()}",
      );

      final response = await dio.post(
        endpoint,
        data: formData,
        options: Options(headers: headers),
      );

      debugPrint("=== COMPLETE PROFILE RESPONSE ===");
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.data}");

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
      debugPrint("=== COMPLETE PROFILE DIO ERROR ===");
      debugPrint("STATUS CODE: ${e.response?.statusCode}");
      debugPrint("ERROR DATA: ${e.response?.data}");
      debugPrint("ERROR MESSAGE: ${e.message}");
      debugPrint("ERROR TYPE: ${e.type}");
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
      throw Exception(e.message ?? 'Something went wrong');
    } catch (e) {
      debugPrint("=== COMPLETE PROFILE UNKNOWN ERROR ===");
      debugPrint("ERROR: $e");
      rethrow;
    }
  }
}
