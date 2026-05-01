import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';

import 'package:gruve_app/features/story_preview/api/story_api/model/stroy_response.dart';
import 'package:gruve_app/features/story_preview/api/story_api/model/story_model.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/features/camera/utils/image_filter_processor.dart';

class StoryService {
  late final Dio _dio;

  StoryService() {
    if (kDebugMode) {
      debugPrint("🌍 StoryService initialized with shared Dio client");
    }
    _dio = AppDio.create(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
    );
  }

  Future<CreateStoryResponse> createStory({
    required String caption,
    required String mediaPath,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint("\n🚀 ===== CREATE STORY START =====");
        debugPrint("🔑 Token: [REDACTED]");
        debugPrint("📝 Caption: $caption");
        debugPrint("📁 File Path: $mediaPath");
      }

      final token = await TokenStorage.getAccessToken();

      File file = File(mediaPath);

      if (!file.existsSync()) {
        if (kDebugMode) {
          debugPrint("❌ File does not exist at path!");
        }
        throw Exception("File not found");
      }

      // Compress image before upload to prevent 413 errors
      if (kDebugMode) {
        debugPrint("🗜️ Compressing image before upload...");
      }
      file = await ImageFilterProcessor.compressImageForUpload(file, maxFileSizeKB: 400);

      final fileName = file.path.replaceAll(r'\', '/').split('/').last;

      if (kDebugMode) {
        debugPrint("📦 Preparing FormData...");
        debugPrint("📄 File Name: $fileName");
        final int fileSizeKB = await file.length() ~/ 1024;
        debugPrint("📏 Final file size: ${fileSizeKB}KB");
      }

      final formData = FormData.fromMap({
        "caption": caption,
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      if (kDebugMode) {
        debugPrint("🔍 FormData Fields: ${formData.fields}");
        debugPrint("📎 FormData Files: ${formData.files}");
        debugPrint("🌐 Hitting API: POST stories/");
      }

      final res = await _dio.post(
        "stories/",
        data: formData,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      if (kDebugMode) {
        debugPrint("✅ ===== SUCCESS RESPONSE =====");
        debugPrint("📊 Status Code: ${res.statusCode}");
        debugPrint("📥 Response Data: ${res.data}");
        debugPrint("🏁 ===== CREATE STORY END =====\n");
      }

      return CreateStoryResponse.fromJson(res.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint("\n❌ ===== DIO ERROR =====");
        debugPrint("⚠️ Type: ${e.type}");
        debugPrint("📊 Status Code: ${e.response?.statusCode}");
        debugPrint("📥 Response Data: ${e.response?.data}");
        debugPrint("🧾 Headers: ${e.response?.headers}");
        debugPrint("🔗 Request Path: ${e.requestOptions.path}");
        debugPrint("📦 Request Data: ${e.requestOptions.data}");
        debugPrint("🚫 ===== ERROR END =====\n");
      }

      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("\n💥 ===== UNKNOWN ERROR =====");
        debugPrint("❌ Error: $e");
        debugPrint("🚫 =========================\n");
      }

      rethrow;
    }
  }

  Future<StoriesResponse> fetchStories({
    String? userId,
    int page = 1,
    int limit = 5,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint("\n🚀 ===== FETCH STORIES START =====");
        debugPrint("🔑 Token: [REDACTED]");
        debugPrint("📄 Page: $page");
        debugPrint("📏 Limit: $limit");
      }

      final token = await TokenStorage.getAccessToken();

      // Dynamic endpoint selection
      final endpoint = userId == null ? "stories/me/" : "stories/user/$userId/";
      final isMe = userId == null;

      if (kDebugMode) {
        debugPrint("🌐 API CALL:");
        debugPrint("➡️ Endpoint: $endpoint");
        debugPrint("➡️ userId: ${userId ?? 'me (own stories)'}");
        debugPrint("➡️ isMe: $isMe");
        debugPrint("🌐 Hitting API: GET $endpoint");
      }

      final res = await _dio.get(
        endpoint,
        queryParameters: {"page": page, "limit": limit},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (kDebugMode) {
        debugPrint("✅ ===== SUCCESS RESPONSE =====");
        debugPrint("📊 Status Code: ${res.statusCode}");
        debugPrint("📥 Response Data: ${res.data}");

        debugPrint("📥 API RESPONSE:");
        if (res.data['data'] != null && res.data['data']['stories'] != null) {
          debugPrint("➡️ Stories count: ${res.data['data']['stories'].length}");
        } else {
          debugPrint("➡️ Stories count: 0 (no stories in response)");
        }

        debugPrint("🏁 ===== FETCH STORIES END =====\n");
      }

      return StoriesResponse.fromJson(res.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint("\n❌ ===== DIO ERROR =====");
        debugPrint("⚠️ Type: ${e.type}");
        debugPrint("📊 Status Code: ${e.response?.statusCode}");
        debugPrint("📥 Response Data: ${e.response?.data}");
        debugPrint("🧾 Headers: ${e.response?.headers}");
        debugPrint("🔗 Request Path: ${e.requestOptions.path}");
        debugPrint("🚫 ===== ERROR END =====\n");
      }

      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("\n💥 ===== UNKNOWN ERROR =====");
        debugPrint("❌ Error: $e");
        debugPrint("🚫 =========================\n");
      }

      rethrow;
    }
  }
}
