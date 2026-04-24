import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:gruve_app/features/story_preview/api/story_api/model/stroy_response.dart';
import 'package:gruve_app/features/story_preview/api/story_api/model/story_model.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class StoryService {
  late final Dio _dio;

  StoryService() {
    var base = dotenv.env['BASE_URL']!.trim();
    if (!base.endsWith('/')) {
      base = '$base/';
    }

    debugPrint("🌍 BASE URL: $base");

    _dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
  }

  Future<CreateStoryResponse> createStory({
    required String caption,
    required String mediaPath,
  }) async {
    try {
      debugPrint("\n🚀 ===== CREATE STORY START =====");

      final token = await TokenStorage.getAccessToken();

      debugPrint("🔑 Token: $token");
      debugPrint("📝 Caption: $caption");
      debugPrint("📁 File Path: $mediaPath");

      final file = File(mediaPath);

      if (!file.existsSync()) {
        debugPrint("❌ File does not exist at path!");
        throw Exception("File not found");
      }

      final fileName = file.path.replaceAll(r'\', '/').split('/').last;

      debugPrint("📦 Preparing FormData...");
      debugPrint("📄 File Name: $fileName");

      final formData = FormData.fromMap({
        "caption": caption,
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      debugPrint("🔍 FormData Fields: ${formData.fields}");
      debugPrint("📎 FormData Files: ${formData.files}");
      debugPrint("🌐 Hitting API: POST stories/");

      final res = await _dio.post(
        "stories/",
        data: formData,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      debugPrint("✅ ===== SUCCESS RESPONSE =====");
      debugPrint("📊 Status Code: ${res.statusCode}");
      debugPrint("📥 Response Data: ${res.data}");
      debugPrint("🏁 ===== CREATE STORY END =====\n");

      return CreateStoryResponse.fromJson(res.data);
    } on DioException catch (e) {
      debugPrint("\n❌ ===== DIO ERROR =====");
      debugPrint("⚠️ Type: ${e.type}");
      debugPrint("📊 Status Code: ${e.response?.statusCode}");
      debugPrint("📥 Response Data: ${e.response?.data}");
      debugPrint("🧾 Headers: ${e.response?.headers}");
      debugPrint("🔗 Request Path: ${e.requestOptions.path}");
      debugPrint("📦 Request Data: ${e.requestOptions.data}");
      debugPrint("🚫 ===== ERROR END =====\n");

      rethrow;
    } catch (e) {
      debugPrint("\n💥 ===== UNKNOWN ERROR =====");
      debugPrint("❌ Error: $e");
      debugPrint("🚫 =========================\n");

      rethrow;
    }
  }

  Future<StoriesResponse> fetchStories({int page = 1, int limit = 5}) async {
    try {
      debugPrint("\n🚀 ===== FETCH STORIES START =====");

      final token = await TokenStorage.getAccessToken();

      debugPrint("🔑 Token: $token");
      debugPrint("📄 Page: $page");
      debugPrint("📏 Limit: $limit");
      debugPrint("🌐 Hitting API: GET stories/me/");

      final res = await _dio.get(
        "stories/me/",
        queryParameters: {
          "page": page,
          "limit": limit,
        },
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      debugPrint("✅ ===== SUCCESS RESPONSE =====");
      debugPrint("📊 Status Code: ${res.statusCode}");
      debugPrint("📥 Response Data: ${res.data}");
      debugPrint("🏁 ===== FETCH STORIES END =====\n");

      return StoriesResponse.fromJson(res.data);
    } on DioException catch (e) {
      debugPrint("\n❌ ===== DIO ERROR =====");
      debugPrint("⚠️ Type: ${e.type}");
      debugPrint("📊 Status Code: ${e.response?.statusCode}");
      debugPrint("📥 Response Data: ${e.response?.data}");
      debugPrint("🧾 Headers: ${e.response?.headers}");
      debugPrint("🔗 Request Path: ${e.requestOptions.path}");
      debugPrint("🚫 ===== ERROR END =====\n");

      rethrow;
    } catch (e) {
      debugPrint("\n💥 ===== UNKNOWN ERROR =====");
      debugPrint("❌ Error: $e");
      debugPrint("🚫 =========================\n");

      rethrow;
    }
  }
}
