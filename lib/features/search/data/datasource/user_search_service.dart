import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class SearchUser {
  final String id;
  final String name;
  final String username;
  final String avatar;
  final bool isOnline;

  const SearchUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    this.isOnline = false,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    final id = _firstString(json, const ['id', '_id', 'user_id', 'uuid']);
    final username = _firstString(json, const ['username', 'user_name', 'handle', 'email']);
    final name = _firstString(json, const ['name', 'full_name', 'display_name', 'first_name', 'username']);
    final avatar = _firstString(json, const ['avatar', 'profile_picture', 'profile_image', 'image', 'photo']);

    return SearchUser(
      id: id.isNotEmpty ? id : username,
      name: name.isNotEmpty ? name : username,
      username: username.isNotEmpty ? username : name,
      avatar: avatar,
      isOnline: json['is_online'] == true || json['isOnline'] == true,
    );
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }
}

class UserSearchService {
  UserSearchService({Dio? dio}) : _dio = dio ?? AppDio.getInstance();

  final Dio _dio;

  Future<List<SearchUser>> searchUsers(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    try {
      final response = await _dio.get(
        ApiConstants.userSearch,
        queryParameters: {'username': trimmedQuery},
        cancelToken: cancelToken,
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return _parseUsers(response.data);
    } on DioException catch (e) {
      AppLogger.d('❌ [UserSearchService] ${e.type}: ${e.message}');
      return [];
    } catch (e) {
      AppLogger.d('❌ [UserSearchService] Unexpected: $e');
      return [];
    }
  }

  List<SearchUser> _parseUsers(dynamic data) {
    final rawUsers = _extractList(data);
    return rawUsers
        .whereType<Map>()
        .map((user) {
          try {
            return SearchUser.fromJson(Map<String, dynamic>.from(user));
          } catch (_) {
            return null;
          }
        })
        .whereType<SearchUser>()
        .where((user) => user.id.isNotEmpty)
        .toList();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is! Map) return const [];
    for (final key in const ['results', 'users', 'data', 'items']) {
      final value = data[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = _extractList(value);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }
}

class DebouncedUserSearch {
  DebouncedUserSearch({
    UserSearchService? service,
    this.delay = const Duration(milliseconds: 300),
  }) : _service = service ?? UserSearchService();

  final UserSearchService _service;
  final Duration delay;
  Timer? _timer;
  CancelToken? _cancelToken;
  int _requestId = 0;

  void search(
    String query, {
    required ValueChanged<List<SearchUser>> onResults,
    required ValueChanged<Object> onError,
  }) {
    _timer?.cancel();
    _cancelToken?.cancel('Superseded by a newer search query');
    _cancelToken = CancelToken();
    final requestId = ++_requestId;
    final cancelToken = _cancelToken;

    _timer = Timer(delay, () async {
      if (requestId != _requestId) return;

      try {
        final results = await _service.searchUsers(
          query,
          cancelToken: cancelToken,
        );
        if (requestId == _requestId) onResults(results);
      } catch (error) {
        if (requestId == _requestId) onError(error);
      }
    });
  }

  void clear() {
    _timer?.cancel();
    _cancelToken?.cancel('Search cleared');
    _cancelToken = null;
    _requestId++;
  }

  void dispose() => clear();
}
