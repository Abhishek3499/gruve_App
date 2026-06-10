import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gruve_app/core/network/app_dio.dart';
import 'package:gruve_app/features/notification/api/models/notification_model.dart';

class NotificationService {
  final Dio _dio = AppDio.create();

  /// Fetch notifications from backend.
  Future<NotificationListResponse> fetchNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        'notifications/',
        queryParameters: {
          'page': page,
          'limit': limit,
          'unread_only': unreadOnly,
        },
      );

      if (response.statusCode == 200) {
        return NotificationListResponse.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch notifications');
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException fetching notifications: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch notifications');
    } catch (e) {
      debugPrint('❌ Unexpected error fetching notifications: $e');
      rethrow;
    }
  }

  /// Get current unread notification count.
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('notifications/unread-count/');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map) {
          final nestedData = data['data'];
          if (nestedData is Map && nestedData.containsKey('unread_count')) {
            return nestedData['unread_count'] ?? 0;
          } else if (data.containsKey('unread_count')) {
            return data['unread_count'] ?? 0;
          }
        }
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Mark specific notifications or all notifications as read.
  Future<bool> markAsRead({
    List<int>? notificationIds,
    bool markAll = false,
  }) async {
    try {
      final Map<String, dynamic> requestData = {};
      if (markAll) {
        requestData['mark_all'] = true;
      } else if (notificationIds != null && notificationIds.isNotEmpty) {
        requestData['notification_ids'] = notificationIds;
      } else {
        return false;
      }

      final response = await _dio.post(
        'notifications/mark-read/',
        data: requestData,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Error marking notifications as read: $e');
      return false;
    }
  }
}
