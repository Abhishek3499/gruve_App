import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/auth/data/services/token_storage.dart';
import 'package:gruve_app/features/connections/domain/entities/connection_user_model.dart';

enum ConnectionType { subscribers, subscribed }

extension ConnectionTypeParam on ConnectionType {
  String get param =>
      this == ConnectionType.subscribers ? 'subscribers' : 'subscribed';
}

class ConnectionsService {
  ConnectionsService() : _dio = AppDio.getInstance();

  final Dio _dio;

  Future<ConnectionsPage> getConnections({
    required String userId,
    required ConnectionType type,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final endpoint = ApiConstants.userConnections(userId);
    final token = await TokenStorage.getAccessToken();

    AppLogger.d(
      '[ConnectionsService] GET $endpoint type=${type.param} page=$page limit=$limit',
    );

    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: {'type': type.param, 'page': page, 'limit': limit},
        cancelToken: cancelToken,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final raw = response.data;
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      final payload = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;

      return ConnectionsPage.fromJson(payload);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.d('[ConnectionsService] getConnections cancelled');
        return ConnectionsPage(
          type: type.param,
          count: 0,
          page: page,
          limit: limit,
          hasNext: false,
          results: const [],
        );
      }
      AppLogger.d('[ConnectionsService] DioException: ${e.message}');
      rethrow;
    }
  }
}
