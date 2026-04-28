import 'package:dio/dio.dart';
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
      print("🚀 [Service] fetchMyHighlights CALLED");

      final token = await TokenStorage.getAccessToken();
      print("🔑 [Service] Token: $token");

      final response = await _dio.get(
        "highlights/mine/",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("🔥 [Service] RESPONSE DATA: ${response.data}");

      return HighlightsResponse.fromJson(response.data);
    } on DioException catch (e) {
      print("❌ [Service] DIO ERROR: ${e.response?.data}");
      print("❌ [Service] STATUS CODE: ${e.response?.statusCode}");
      rethrow;
    } catch (e) {
      print("❌ [Service] UNKNOWN ERROR: $e");
      rethrow;
    }
  }
}
