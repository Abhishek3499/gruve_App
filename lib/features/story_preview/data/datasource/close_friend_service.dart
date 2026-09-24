import 'package:dio/dio.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/search/data/datasource/user_search_service.dart';

class CloseFriendPage {
  final List<SearchUser> users;
  final int page;
  final bool hasNext;

  const CloseFriendPage({
    required this.users,
    required this.page,
    required this.hasNext,
  });
}

/// Fetches the logged-in user's "subscribed" connections — the candidate
/// pool for the Close Friends picker.
class CloseFriendService {
  CloseFriendService({Dio? dio}) : _dio = dio ?? AppDio.getInstance();

  final Dio _dio;

  Future<CloseFriendPage> fetchSubscribedConnections({
    required String userId,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.userConnections(userId),
      queryParameters: {'type': 'subscribed', 'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );

    final data = response.data is Map
        ? Map<String, dynamic>.from(
            (response.data as Map)['data'] as Map? ?? const {},
          )
        : <String, dynamic>{};

    final rawResults = data['results'];
    final users = rawResults is List
        ? rawResults
              .whereType<Map>()
              .map((e) => SearchUser.fromJson(Map<String, dynamic>.from(e)))
              .where((user) => user.id.isNotEmpty)
              .toList()
        : <SearchUser>[];

    AppLogger.d(
      '[CloseFriendService] page=${data['page'] ?? page} '
      'count=${users.length} hasNext=${data['has_next']}',
    );

    return CloseFriendPage(
      users: users,
      page: (data['page'] as num?)?.toInt() ?? page,
      hasNext: data['has_next'] == true,
    );
  }

  /// Replaces the logged-in user's close-friends list with exactly
  /// [userIds] — the backend adds/removes members by diffing against the
  /// previous list, so the full desired set is sent on every call.
  Future<void> updateCloseFriends(List<String> userIds) async {
    await _dio.put<dynamic>(
      ApiConstants.closeFriends,
      data: {'user_ids': userIds},
    );
  }
}
