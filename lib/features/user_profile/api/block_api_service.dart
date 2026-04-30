import 'package:dio/dio.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/screens/auth/token_storage.dart';
import '../models/block_toggle_response_model.dart';

class BlockApiService {
  static const String _toggleEndpoint = 'profile/block/toggle';

  late final Dio _dio;

  void _log(String message) {
    print('🌐 [BlockApiService] $message');
  }

  BlockApiService() {
    _dio = AppDio.create(receiveTimeout: const Duration(seconds: 45));
    _log('Initialized shared Dio client');
  }

  Future<BlockToggleResponseModel> toggleBlockUser(String userId) async {
    try {
      _log('🚀 API START - toggleBlockUser for userId=$userId');
      final token = await TokenStorage.getAccessToken();
      _log('📡 POST $_toggleEndpoint');
      _log('📦 request body={user_id: $userId}');

      final response = await _dio.post(
        _toggleEndpoint,
        data: {'user_id': userId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      _log('✅ API SUCCESS - status=${response.statusCode}');
      _log('🧾 response data=${response.data}');

      final result = BlockToggleResponseModel.fromJson(response.data);
      _log('🎯 parsed isBlocked=${result.data?.isBlocked}');

      return result;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      _log('❌ API ERROR - DioException type=${e.type}');
      _log('❌ statusCode=$statusCode');
      _log('❌ responseData=$responseData');
      _log('❌ message=${e.message}');

      rethrow;
    } catch (e) {
      _log('❌ API ERROR - Unexpected error: $e');
      rethrow;
    }
  }
}
