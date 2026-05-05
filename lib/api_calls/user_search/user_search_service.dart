import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';

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
    debugPrint('🔄 [SearchUser] Parsing user from JSON...');
    debugPrint('📄 [SearchUser] Raw JSON: $json');

    final id = _firstString(json, const ['id', '_id', 'user_id', 'uuid']);
    final username = _firstString(json, const [
      'username',
      'user_name',
      'handle',
      'email',
    ]);
    final name = _firstString(json, const [
      'name',
      'full_name',
      'display_name',
      'first_name',
      'username',
    ]);
    final avatar = _firstString(json, const [
      'avatar',
      'profile_picture',
      'profile_image',
      'image',
      'photo',
    ]);

    debugPrint(
      '✅ [SearchUser] Parsed: id=$id, name=$name, username=$username, avatar=${avatar.isNotEmpty ? "present" : "empty"}',
    );

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
  UserSearchService({Dio? dio}) : _dio = dio ?? AppDio.create();

  final Dio _dio;

  Future<List<SearchUser>> searchUsers(String query) async {
    debugPrint('🔍 [UserSearchService] ========== SEARCH START ==========');
    debugPrint('🔍 [UserSearchService] Query: "$query"');

    final trimmedQuery = query.trim();
    debugPrint('🔍 [UserSearchService] Trimmed query: "$trimmedQuery"');

    if (trimmedQuery.isEmpty) {
      debugPrint('⚠️ [UserSearchService] Empty query, returning empty list');
      debugPrint('🔍 [UserSearchService] ========== SEARCH END ==========');
      return const [];
    }

    try {
      debugPrint('🌐 [UserSearchService] Making API call...');
      debugPrint('🌐 [UserSearchService] Endpoint: /user/users/search/');
      debugPrint('🌐 [UserSearchService] Query params: {q: $trimmedQuery}');

      final response = await _dio.get(
        'user/users/search/',
        queryParameters: {'username': trimmedQuery},
      );

      debugPrint('✅ [UserSearchService] API call successful');
      debugPrint('📊 [UserSearchService] Status code: ${response.statusCode}');
      debugPrint(
        '📊 [UserSearchService] Response type: ${response.data.runtimeType}',
      );
      debugPrint('📄 [UserSearchService] Response data: ${response.data}');

      final users = _parseUsers(response.data);
      debugPrint('✅ [UserSearchService] Parsed ${users.length} users');
      debugPrint('🔍 [UserSearchService] ========== SEARCH END ==========');

      return users;
    } on DioException catch (e) {
      debugPrint('❌ [UserSearchService] ========== SEARCH FAILED ==========');
      debugPrint('❌ [UserSearchService] DioException caught');
      debugPrint('❌ [UserSearchService] Type: ${e.type}');
      debugPrint('❌ [UserSearchService] Message: ${e.message}');
      debugPrint(
        '❌ [UserSearchService] Status code: ${e.response?.statusCode}',
      );
      debugPrint('❌ [UserSearchService] Response data: ${e.response?.data}');
      debugPrint(
        '❌ [UserSearchService] Request path: ${e.requestOptions.path}',
      );
      debugPrint(
        '❌ [UserSearchService] Request query: ${e.requestOptions.queryParameters}',
      );
      debugPrint(
        '❌ [UserSearchService] Request headers: ${e.requestOptions.headers}',
      );

      if (e.response?.statusCode == 422) {
        debugPrint('⚠️ [UserSearchService] 422 Error - Unprocessable Entity');
        debugPrint('⚠️ [UserSearchService] This usually means:');
        debugPrint('   - Invalid query parameter format');
        debugPrint('   - Query too short (minimum length required)');
        debugPrint('   - Query contains invalid characters');
        debugPrint('   - Missing required parameters');
      } else if (e.response?.statusCode == 404) {
        debugPrint('⚠️ [UserSearchService] 404 Error - Not Found');
        debugPrint('⚠️ [UserSearchService] This usually means:');
        debugPrint('   - Endpoint does not exist');
        debugPrint('   - Wrong API path');
        debugPrint('   - API version mismatch');
      }

      debugPrint('🔍 [UserSearchService] ========== SEARCH END ==========');
      rethrow;
    } catch (e) {
      debugPrint(
        '❌ [UserSearchService] ========== UNEXPECTED ERROR ==========',
      );
      debugPrint('❌ [UserSearchService] Error type: ${e.runtimeType}');
      debugPrint('❌ [UserSearchService] Error: $e');
      debugPrint('🔍 [UserSearchService] ========== SEARCH END ==========');
      rethrow;
    }
  }

  List<SearchUser> _parseUsers(dynamic data) {
    debugPrint('🔄 [UserSearchService] Parsing users from response...');
    debugPrint('📊 [UserSearchService] Data type: ${data.runtimeType}');

    final rawUsers = _extractList(data);
    debugPrint(
      '📊 [UserSearchService] Extracted ${rawUsers.length} raw user objects',
    );

    final users = rawUsers
        .whereType<Map>()
        .map((user) {
          try {
            return SearchUser.fromJson(Map<String, dynamic>.from(user));
          } catch (e) {
            debugPrint('⚠️ [UserSearchService] Failed to parse user: $e');
            debugPrint('⚠️ [UserSearchService] User data: $user');
            return null;
          }
        })
        .whereType<SearchUser>()
        .where((user) {
          final hasId = user.id.isNotEmpty;
          if (!hasId) {
            debugPrint(
              '⚠️ [UserSearchService] Skipping user with empty ID: ${user.username}',
            );
          }
          return hasId;
        })
        .toList();

    debugPrint(
      '✅ [UserSearchService] Successfully parsed ${users.length} valid users',
    );
    return users;
  }

  List<dynamic> _extractList(dynamic data) {
    debugPrint('🔄 [UserSearchService] Extracting list from data...');
    debugPrint('📊 [UserSearchService] Data type: ${data.runtimeType}');

    if (data is List) {
      debugPrint(
        '✅ [UserSearchService] Data is already a list with ${data.length} items',
      );
      return data;
    }

    if (data is! Map) {
      debugPrint(
        '⚠️ [UserSearchService] Data is neither List nor Map, returning empty',
      );
      return const [];
    }

    debugPrint('🔍 [UserSearchService] Searching for list in map keys...');
    debugPrint('📊 [UserSearchService] Available keys: ${data.keys.toList()}');

    for (final key in const ['results', 'users', 'data', 'items']) {
      debugPrint('🔍 [UserSearchService] Checking key: "$key"');
      final value = data[key];

      if (value is List) {
        debugPrint(
          '✅ [UserSearchService] Found list at key "$key" with ${value.length} items',
        );
        return value;
      }

      if (value is Map) {
        debugPrint(
          '🔍 [UserSearchService] Key "$key" contains nested map, searching recursively...',
        );
        final nested = _extractList(value);
        if (nested.isNotEmpty) {
          debugPrint(
            '✅ [UserSearchService] Found list in nested map with ${nested.length} items',
          );
          return nested;
        }
      }
    }

    debugPrint(
      '⚠️ [UserSearchService] No list found in any expected keys, returning empty',
    );
    return const [];
  }
}

class DebouncedUserSearch {
  DebouncedUserSearch({
    UserSearchService? service,
    this.delay = const Duration(milliseconds: 450),
  }) : _service = service ?? UserSearchService() {
    debugPrint(
      '🔧 [DebouncedUserSearch] Initialized with delay: ${delay.inMilliseconds}ms',
    );
  }

  final UserSearchService _service;
  final Duration delay;
  Timer? _timer;
  int _requestId = 0;

  void search(
    String query, {
    required ValueChanged<List<SearchUser>> onResults,
    required ValueChanged<Object> onError,
  }) {
    debugPrint('🔍 [DebouncedUserSearch] Search triggered for: "$query"');

    _timer?.cancel();
    final requestId = ++_requestId;

    debugPrint('🔍 [DebouncedUserSearch] Request ID: $requestId');
    debugPrint(
      '🔍 [DebouncedUserSearch] Debouncing for ${delay.inMilliseconds}ms...',
    );

    _timer = Timer(delay, () async {
      debugPrint(
        '⏰ [DebouncedUserSearch] Debounce timer expired, executing search...',
      );
      debugPrint(
        '🔍 [DebouncedUserSearch] Request ID: $requestId (current: $_requestId)',
      );

      try {
        final results = await _service.searchUsers(query);

        if (requestId == _requestId) {
          debugPrint(
            '✅ [DebouncedUserSearch] Request $requestId is still current, returning ${results.length} results',
          );
          onResults(results);
        } else {
          debugPrint(
            '⚠️ [DebouncedUserSearch] Request $requestId is stale (current: $_requestId), ignoring results',
          );
        }
      } catch (error) {
        debugPrint(
          '❌ [DebouncedUserSearch] Search error for request $requestId: $error',
        );

        if (requestId == _requestId) {
          debugPrint(
            '❌ [DebouncedUserSearch] Request $requestId is still current, calling onError',
          );
          onError(error);
        } else {
          debugPrint(
            '⚠️ [DebouncedUserSearch] Request $requestId is stale (current: $_requestId), ignoring error',
          );
        }
      }
    });
  }

  void clear() {
    debugPrint('🧹 [DebouncedUserSearch] Clearing search...');
    _timer?.cancel();
    _requestId++;
    debugPrint('🧹 [DebouncedUserSearch] New request ID: $_requestId');
  }

  void dispose() {
    debugPrint('🗑️ [DebouncedUserSearch] Disposing...');
    clear();
  }
}
