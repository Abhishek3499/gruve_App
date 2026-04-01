import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';

class ProfileService {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['BASE_URL']!));

  Future<Map<String, dynamic>> getUser() async {
    debugPrint("[ProfileService] getUser() called");
    debugPrint("[ProfileService] baseUrl: ${dotenv.env['BASE_URL']}");

    final token = await TokenStorage.getAccessToken();
    final tokenPreview = token == null || token.isEmpty
        ? "null_or_empty"
        : "${token.substring(0, token.length > 12 ? 12 : token.length)}...";
    debugPrint("[ProfileService] token preview: $tokenPreview");

    debugPrint("[ProfileService] GET user/profile_data/");

    final response = await _dio.get(
      "user/profile_data/",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    debugPrint("[ProfileService] status code: ${response.statusCode}");
    debugPrint("[ProfileService] response data: ${response.data}");

    return response.data["data"]["user"];
  }
}
