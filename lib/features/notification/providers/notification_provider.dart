import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:gruve_app/features/notification/api/models/notification_model.dart';
import 'package:gruve_app/features/notification/api/services/notification_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/services/socket_service.dart';
import 'package:gruve_app/core/auth/current_user_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  final SocketService _socketService = SocketService();
  StreamSubscription? _socketSubscription;

  NotificationProvider() {
    _initializeSocketListener();
  }

  void _initializeSocketListener() {
    _socketSubscription = _socketService.messageStream.listen((data) {
      try {
        final type = data['type']?.toString().toLowerCase() ?? '';
        if (type.contains('notification') ||
            type.contains('alert') ||
            type.contains('like') ||
            type.contains('comment') ||
            type.contains('follow')) {
          AppLogger.d('🔔 [NotificationProvider] Socket notification received. Refreshing list...');
          fetchInitialNotifications(showLoading: false);
        }
      } catch (e) {
        AppLogger.d('❌ [NotificationProvider] Socket error: $e');
      }
    });
  }

  List<AppNotification> _notifications = [];
  CancelToken? _cancelToken;

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Screen disposed');
    _cancelToken = null;
  }

  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _unreadCount = 0;
  int _lastCurrentUserUnreadCount = -1;
  int _currentPage = 1;
  bool _hasNextPage = false;
  String _errorMessage = '';
  bool _unreadOnly = false;
  String? _lastPaginationKey;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  int get unreadCount => _unreadCount;
  int get currentPage => _currentPage;
  bool get hasNextPage => _hasNextPage;
  String get errorMessage => _errorMessage;
  bool get unreadOnly => _unreadOnly;

  /// Update the filter between "All" vs "Unread" only and refetch.
  void setUnreadOnly(bool value) {
    if (_unreadOnly != value) {
      _unreadOnly = value;
      notifyListeners();
      fetchInitialNotifications(showLoading: true);
    }
  }

  /// Manually set the unread notifications count.
  void setUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  /// Syncs unread count from the CurrentUserProvider without overwriting newer client updates.
  void updateFromCurrentUser(CurrentUserProvider currentUserProvider) {
    final count = currentUserProvider.unreadNotificationCount;
    if (_lastCurrentUserUnreadCount != count) {
      _lastCurrentUserUnreadCount = count;
      _unreadCount = count;
      notifyListeners();
    }
  }

  /// Get the current unread notifications count from backend.
  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount(cancelToken: _getCancelToken());
      notifyListeners();
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('[NotificationProvider] fetchUnreadCount cancelled');
        return;
      }
      AppLogger.d('❌ Error fetching unread count: $e');
    }
  }

  /// Fetch initial list of notifications.
  Future<void> fetchInitialNotifications({bool showLoading = true}) async {
    AppLogger.d(
      '📡 [NotificationProvider] fetchInitial trigger=${showLoading ? 'initial' : 'refresh'} '
      'page=1 unreadOnly=$_unreadOnly',
    );

    _lastPaginationKey = null;
    if (showLoading) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      final response = await _service.fetchNotifications(
        page: 1,
        unreadOnly: _unreadOnly,
        cancelToken: _getCancelToken(),
      );

      if (response.success && response.data != null) {
        _notifications = response.data!.results;
        _unreadCount = response.data!.unreadCount;
        _currentPage = response.data!.page;
        _hasNextPage = response.data!.hasNext;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('[NotificationProvider] fetchInitialNotifications cancelled');
        return;
      }
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page for pagination/infinite scroll.
  Future<void> fetchNextPage({String reason = 'scroll'}) async {
    if (_isLoadingMore || !_hasNextPage || _isLoading) return;

    final nextPage = _currentPage + 1;
    final requestKey = 'page=$nextPage|unreadOnly=$_unreadOnly';
    if (_lastPaginationKey == requestKey) {
      AppLogger.d(
        '⏸️ [NotificationProvider] fetchNextPage skipped duplicate '
        'reason=$reason $requestKey',
      );
      return;
    }
    _lastPaginationKey = requestKey;

    AppLogger.d(
      '📡 [NotificationProvider] fetchNextPage trigger=$reason $requestKey',
    );

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _service.fetchNotifications(
        page: nextPage,
        unreadOnly: _unreadOnly,
        cancelToken: _getCancelToken(),
      );

      if (response.success && response.data != null) {
        _notifications.addAll(response.data!.results);
        _unreadCount = response.data!.unreadCount;
        _currentPage = response.data!.page;
        _hasNextPage = response.data!.hasNext;
        _lastPaginationKey = null;
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('[NotificationProvider] fetchNextPage cancelled');
        return;
      }
      _lastPaginationKey = null;
      AppLogger.d('❌ Error loading next page: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Mark a single notification as read with optimistic updates.
  Future<void> markNotificationAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    final originalNotification = _notifications[index];
    _notifications[index] = originalNotification.copyWith(isRead: true);
    if (_unreadCount > 0) {
      _unreadCount--;
    }
    notifyListeners();

    final success = await _service.markAsRead(
      notificationIds: [notificationId],
      cancelToken: _getCancelToken(),
    );
    if (!success) {
      // Revert if the server call failed
      _notifications[index] = originalNotification;
      _unreadCount++;
      notifyListeners();
    } else {
      await fetchUnreadCount();
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllNotificationsAsRead() async {
    if (_unreadCount == 0) return;

    final originalNotifications = List<AppNotification>.from(_notifications);
    final originalUnreadCount = _unreadCount;

    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();

    final success = await _service.markAsRead(
      markAll: true,
      cancelToken: _getCancelToken(),
    );
    if (!success) {
      // Revert on failure
      _notifications = originalNotifications;
      _unreadCount = originalUnreadCount;
      notifyListeners();
    } else {
      await fetchUnreadCount();
    }
  }

  // Time groupings
  List<AppNotification> get newNotifications {
    final now = DateTime.now();
    return _notifications.where((n) {
      final date = DateTime.tryParse(n.createdAt) ?? now;
      final diff = now.difference(date);
      return diff.inHours < 2;
    }).toList();
  }

  List<AppNotification> get todayNotifications {
    final now = DateTime.now();
    return _notifications.where((n) {
      final date = DateTime.tryParse(n.createdAt) ?? now;
      final diff = now.difference(date);
      return diff.inHours >= 2 &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  List<AppNotification> get thisWeekNotifications {
    final now = DateTime.now();
    return _notifications.where((n) {
      final date = DateTime.tryParse(n.createdAt) ?? now;
      final diff = now.difference(date);
      final isSameDay = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      return !isSameDay && diff.inDays < 7;
    }).toList();
  }

  List<AppNotification> get earlierNotifications {
    final now = DateTime.now();
    return _notifications.where((n) {
      final date = DateTime.tryParse(n.createdAt) ?? now;
      final diff = now.difference(date);
      final isSameDay = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      return !isSameDay && diff.inDays >= 7;
    }).toList();
  }

  /// Helper to format raw API datetime into display format (e.g. "3h", "2d")
  static String formatTime(String createdAtStr) {
    if (createdAtStr.isEmpty) return '';
    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.isNegative) return 'now';

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    }
  }

  void reset() {
    cancelActiveRequests();
    _notifications = [];
    _isLoading = false;
    _isLoadingMore = false;
    _unreadCount = 0;
    _lastCurrentUserUnreadCount = -1;
    _currentPage = 1;
    _hasNextPage = false;
    _errorMessage = '';
    _unreadOnly = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    cancelActiveRequests();
    super.dispose();
  }
}
