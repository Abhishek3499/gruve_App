import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';

class AccountTypeService {
  AccountTypeService() : _dio = AppDio.getInstance();

  final Dio _dio;

  /// Returns the updated account_type string ("public" or "private").
  Future<String> setAccountType(String accountType) async {
    final token = await TokenStorage.getAccessToken();
    final response = await _dio.put(
      ApiConstants.accountType,
      data: {'account_type': accountType},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        extra: {'skipCache': true},
      ),
    );
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>)['account_type'] as String;
  }
}
