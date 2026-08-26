import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/auth/data/datasource/token_storage.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/user_profile/data/dto/report_user_response_model.dart';

class ReportUserApiService {
  static const String _endpoint = ApiConstants.reportUser;

  late final Dio _dio;

  ReportUserApiService() {
    _dio = AppDio.getInstance();
  }

  void _log(String message) {
    AppLogger.d('[ReportUserApiService] $message');
  }

  Future<ReportUserResponseModel> reportUser({
    required String userId,
    required String reasonKey,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedReason = reasonKey.trim();

    if (trimmedUserId.isEmpty) {
      throw ArgumentError('user_id is required');
    }
    if (trimmedReason.isEmpty) {
      throw ArgumentError('reason_key is required');
    }

    try {
      _log('POST $_endpoint user_id=$trimmedUserId reason_key=$trimmedReason');
      final token = await TokenStorage.getAccessToken();

      final response = await _dio.post(
        _endpoint,
        data: {
          'user_id': trimmedUserId,
          'reason_key': trimmedReason,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {
            'skipCache': true,
            'bypassCache': true,
            'noCache': true,
          },
        ),
      );

      _log('Success status=${response.statusCode}');
      return ReportUserResponseModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      _log('DioException status=${e.response?.statusCode} data=${e.response?.data}');
      rethrow;
    }
  }

  static String errorMessageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final explicit = map['error']?.toString().trim();
      if (explicit != null && explicit.isNotEmpty) return explicit;

      final message = map['message']?.toString().trim();
      if (message != null &&
          message.isNotEmpty &&
          message.toLowerCase() != 'request failed.') {
        return message;
      }
    }

    switch (error.response?.statusCode) {
      case 401:
        return 'Please sign in again to report this user.';
      case 404:
        return 'User not found.';
      case 409:
        return 'You have already reported this user.';
      default:
        return 'Failed to report user. Please try again.';
    }
  }
}
