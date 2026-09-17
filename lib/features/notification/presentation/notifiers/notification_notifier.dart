import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:gruve_app/features/notification/domain/entities/notification_model.dart';
import 'package:gruve_app/features/notification/data/datasource/notification_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/services/socket_service.dart';
import 'package:gruve_app/core/auth/current_user_notifier.dart';

/// Immutable state for [NotificationNotifier]: the notification list, its
/// pagination/loading flags, the unread count and the current "All"/"Unread" filter.
@immutable
class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.unreadCount = 0,
    this.currentPage = 1,
    this.hasNextPage = false,
    this.errorMessage = '',
    this.unreadOnly = false,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final int unreadCount;
  final int currentPage;
  final bool hasNextPage;
  final String errorMessage;
  final bool unreadOnly;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    int? unreadCount,
    int? currentPage,
    bool? hasNextPage,
    String? errorMessage,
    bool? unreadOnly,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      errorMessage: errorMessage ?? this.errorMessage,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }

  // Time groupings
  List<AppNotification> get newNotifications {
    final now = DateTime.now();
    return notifications.where((n) {
      final date = DateTime.tryParse(n.createdAt) ?? now;
      final diff = now.difference(date);
      return diff.inHours < 2;
    }).toList();
  }

  List<AppNotification> get todayNotifications {
    final now = DateTime.now();
    return notifications.where((n) {
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
    return notifications.where((n) {
      final date = DateTime.tryParse(n.createdAt) ?? now;
      final diff = now.difference(date);
      final isSameDay =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      return !isSameDay && diff.inDays < 7;
    }).toList();
  }

  List<AppNotification> get earlierNotifications {
    final now = DateTime.now();
    return notifications.where((n) {
      final date = DateTime.tryParse(n.createdAt) ?? now;
      final diff = now.difference(date);
      final isSameDay =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      return !isSameDay && diff.inDays >= 7;
    }).toList();
  }
}

/// Replaces the previous `NotificationProvider` (ChangeNotifier) and the
/// `_CurrentUserNotificationBridge` in `main.dart`. Owns the notification
/// list, pagination, unread count and socket-driven refresh, and syncs its
/// initial unread count directly from [CurrentUserNotifier].
class NotificationNotifier extends Notifier<NotificationState> {
  final NotificationService _service = NotificationService();
  final SocketService _socketService = SocketService();
  StreamSubscription? _socketSubscription;
  CancelToken? _cancelToken;
  int _lastCurrentUserUnreadCount = -1;
  String? _lastPaginationKey;

  @override
  NotificationState build() {
    _initializeSocketListener();

    // Syncs unread count from CurrentUserNotifier without overwriting newer
    // client updates (mirrors the previous _CurrentUserNotificationBridge).
    ref.listen<int>(
      currentUserNotifierProvider.select((s) => s.unreadNotificationCount),
      (previous, next) => _updateFromCurrentUser(next),
      fireImmediately: true,
    );

    ref.onDispose(() {
      _socketSubscription?.cancel();
      _cancelToken?.cancel('Notifier disposed');
    });

    return const NotificationState();
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
          AppLogger.d(
            '🔔 [NotificationNotifier] Socket notification received. Refreshing list...',
          );
          fetchInitialNotifications(showLoading: false);
        }
      } catch (e) {
        AppLogger.d('❌ [NotificationNotifier] Socket error: $e');
      }
    });
  }

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Screen disposed');
    _cancelToken = null;
  }

  /// Update the filter between "All" vs "Unread" only and refetch.
  void setUnreadOnly(bool value) {
    if (state.unreadOnly != value) {
      state = state.copyWith(unreadOnly: value);
      fetchInitialNotifications(showLoading: true);
    }
  }

  void _updateFromCurrentUser(int count) {
    if (_lastCurrentUserUnreadCount != count) {
      _lastCurrentUserUnreadCount = count;
      state = state.copyWith(unreadCount: count);
    }
  }

  /// Get the current unread notifications count from backend.
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _service.getUnreadCount(
        cancelToken: _getCancelToken(),
      );
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('[NotificationNotifier] fetchUnreadCount cancelled');
        return;
      }
      AppLogger.d('❌ Error fetching unread count: $e');
    }
  }

  /// Fetch initial list of notifications.
  Future<void> fetchInitialNotifications({bool showLoading = true}) async {
    AppLogger.d(
      '📡 [NotificationNotifier] fetchInitial trigger=${showLoading ? 'initial' : 'refresh'} '
      'page=1 unreadOnly=${state.unreadOnly}',
    );

    _lastPaginationKey = null;
    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: '');
    }

    try {
      final response = await _service.fetchNotifications(
        page: 1,
        unreadOnly: state.unreadOnly,
        cancelToken: _getCancelToken(),
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          notifications: response.data!.results,
          unreadCount: response.data!.unreadCount,
          currentPage: response.data!.page,
          hasNextPage: response.data!.hasNext,
        );
      } else {
        state = state.copyWith(errorMessage: response.message);
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d(
          '[NotificationNotifier] fetchInitialNotifications cancelled',
        );
        return;
      }
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Load next page for pagination/infinite scroll.
  Future<void> fetchNextPage({String reason = 'scroll'}) async {
    if (state.isLoadingMore || !state.hasNextPage || state.isLoading) return;

    final nextPage = state.currentPage + 1;
    final requestKey = 'page=$nextPage|unreadOnly=${state.unreadOnly}';
    if (_lastPaginationKey == requestKey) {
      AppLogger.d(
        '⏸️ [NotificationNotifier] fetchNextPage skipped duplicate '
        'reason=$reason $requestKey',
      );
      return;
    }
    _lastPaginationKey = requestKey;

    AppLogger.d(
      '📡 [NotificationNotifier] fetchNextPage trigger=$reason $requestKey',
    );

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _service.fetchNotifications(
        page: nextPage,
        unreadOnly: state.unreadOnly,
        cancelToken: _getCancelToken(),
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          notifications: [...state.notifications, ...response.data!.results],
          unreadCount: response.data!.unreadCount,
          currentPage: response.data!.page,
          hasNextPage: response.data!.hasNext,
        );
        _lastPaginationKey = null;
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('[NotificationNotifier] fetchNextPage cancelled');
        return;
      }
      _lastPaginationKey = null;
      AppLogger.d('❌ Error loading next page: $e');
    } finally {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Mark a single notification as read with optimistic updates.
  Future<void> markNotificationAsRead(int notificationId) async {
    final index = state.notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || state.notifications[index].isRead) return;

    final originalNotification = state.notifications[index];
    final optimisticList = [...state.notifications];
    optimisticList[index] = originalNotification.copyWith(isRead: true);
    state = state.copyWith(
      notifications: optimisticList,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );

    final success = await _service.markAsRead(
      notificationIds: [notificationId],
      cancelToken: _getCancelToken(),
    );
    if (!success) {
      // Revert if the server call failed
      final revertedList = [...state.notifications];
      revertedList[index] = originalNotification;
      state = state.copyWith(
        notifications: revertedList,
        unreadCount: state.unreadCount + 1,
      );
    } else {
      await fetchUnreadCount();
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllNotificationsAsRead() async {
    if (state.unreadCount == 0) return;

    final originalNotifications = state.notifications;
    final originalUnreadCount = state.unreadCount;

    state = state.copyWith(
      notifications: [
        for (final n in state.notifications)
          if (!n.isRead) n.copyWith(isRead: true) else n,
      ],
      unreadCount: 0,
    );

    final success = await _service.markAsRead(
      markAll: true,
      cancelToken: _getCancelToken(),
    );
    if (!success) {
      // Revert on failure
      state = state.copyWith(
        notifications: originalNotifications,
        unreadCount: originalUnreadCount,
      );
    } else {
      await fetchUnreadCount();
    }
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

  /// Reset all notification data on logout.
  void reset() {
    cancelActiveRequests();
    _lastCurrentUserUnreadCount = -1;
    _lastPaginationKey = null;
    state = const NotificationState();
  }
}

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
