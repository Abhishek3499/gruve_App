import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';

class HighlightService {
  late final Dio _dio;

  HighlightService() {
    _dio = AppDio.create(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
    );
  }
  Future<HighlightsResponse> fetchMyHighlights() async {
    try {
      print("?? [Service] fetchMyHighlights CALLED");

      final token = await TokenStorage.getAccessToken();
      print("?? [Service] Token: $token");

      final response = await _dio.get(
        "highlights/mine/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("?? [Service] RESPONSE DATA: ${response.data}");

      return HighlightsResponse.fromJson(response.data);
    } on DioException catch (e) {
      print("?? [Service] DIO ERROR: ${e.response?.data}");
      print("?? [Service] STATUS CODE: ${e.response?.statusCode}");
      rethrow;
    } catch (e) {
      print("?? [Service] UNKNOWN ERROR: $e");
      rethrow;
    }
  }

  Future<HighlightResponse> fetchHighlightStories(String highlightId) async {
    try {
      debugPrint('[API] Correct endpoint hit');
      debugPrint('[API] highlightId: $highlightId');

      final token = await TokenStorage.getAccessToken();
      debugPrint('[API] Token: ${token?.isNotEmpty == true ? 'Present' : 'Missing'}');

      final response = await _dio.get(
        "highlights/$highlightId/stories/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      debugPrint('[API] RESPONSE STATUS: ${response.statusCode}');
      debugPrint('[API] RESPONSE DATA: ${response.data}');
      
      if (response.data['stories'] != null) {
        debugPrint('[API] stories count: ${response.data['stories'].length}');
      }

      return HighlightResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[API] DIO ERROR: ${e.response?.data}');
      debugPrint('[API] STATUS CODE: ${e.response?.statusCode}');
      debugPrint('[API] ENDPOINT: /highlights/$highlightId/stories/');
      rethrow;
    } catch (e) {
      debugPrint('[API] UNKNOWN ERROR: $e');
      rethrow;
    }
  }
}
