import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/network/api_client.dart';
import 'package:gruve_app/features/message/data/datasource/user_remote_datasource.dart';
import 'package:gruve_app/features/message/domain/repository/user_repository.dart';
import 'package:gruve_app/features/message/domain/entities/user_entity.dart';
import 'package:gruve_app/features/message/data/repo/user_repository_impl.dart';
import 'package:gruve_app/features/message/data/dto/user_model.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/constants/api_constants.dart';
import 'package:gruve_app/core/storage/hive_service.dart';
import 'package:gruve_app/core/cache/cache_manager.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/features/home/presentation/controllers/subscribe_notifier.dart';

@immutable
class UserState {
  final List<UserEntity> users;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasNext;
  final int currentPage;
  final String? errorMessage;
  final bool hasInitialized;

  const UserState({
    this.users = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasNext = true,
    this.currentPage = 1,
    this.errorMessage,
    this.hasInitialized = false,
  });

  UserState copyWith({
    List<UserEntity>? users,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasNext,
    int? currentPage,
    String? errorMessage,
    bool? hasInitialized,
    bool clearError = false,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasInitialized: hasInitialized ?? this.hasInitialized,
    );
  }
}

/// Replaces the previous `UserProvider` (ChangeNotifier). Owns the
/// subscribed user list, pagination, Hive caching, and subscription/auth listeners.
class UserNotifier extends Notifier<UserState> {
  final UserRepository repository;

  UserNotifier({UserRepository? repository})
    : repository =
          repository ?? UserRepositoryImpl(UserRemoteDataSource(ApiClient()));

  Timer? _subscriptionDebounceTimer;
  bool _needsRefreshAfterCurrent = false;
  bool _subscriptionListDirty = false;
  Set<String> _localSubscribedUserIds = {};
  String? _trackedAuthUserId;

  CancelToken? _cancelToken;
  DateTime? _lastFetchTime;
  Future<void>? _fetchInFlight;
  Future<void>? _loadMoreInFlight;
  String? _lastLoadMoreKey;

  static const _cacheValidDuration = Duration(minutes: 2);
  static const _cacheBypassReasons = {
    'subscription_change',
    'pull_to_refresh',
    'tab_visible',
  };

  @override
  UserState build() {
    AppLogger.d('🔥 UserNotifier BUILD CALLED');
    _trackedAuthUserId = AuthStateManager().currentUserId;
    _localSubscribedUserIds = _collectLocalSubscribedUserIds(
      SubscribeNotifier(),
    );
    SubscribeNotifier().addListener(_onSubscriptionChanged);
    AuthStateManager().addListener(_onAuthStateChanged);

    ref.onDispose(() {
      AuthStateManager().removeListener(_onAuthStateChanged);
      SubscribeNotifier().removeListener(_onSubscriptionChanged);
      _subscriptionDebounceTimer?.cancel();
      cancelActiveRequests();
      AppLogger.d('🗑️ [UserNotifier] Disposed');
    });

    return const UserState();
  }

  void _onAuthStateChanged() {
    final authUserId = AuthStateManager().currentUserId;
    if (authUserId == _trackedAuthUserId) return;

    AppLogger.d(
      '🔄 [UserNotifier] Auth user changed $_trackedAuthUserId -> $authUserId, clearing list',
    );
    _trackedAuthUserId = authUserId;
    _clearUserListState();
  }

  void _clearUserListState() {
    _subscriptionDebounceTimer?.cancel();
    _needsRefreshAfterCurrent = false;
    _lastFetchTime = null;
    _fetchInFlight = null;
    _loadMoreInFlight = null;
    _lastLoadMoreKey = null;
    _subscriptionListDirty = false;
    _localSubscribedUserIds = {};
    state = const UserState();
  }

  Set<String> _collectLocalSubscribedUserIds(SubscribeNotifier controller) {
    return controller.users.entries
        .where((e) => e.value.isSubscribed)
        .map((e) => e.key)
        .toSet();
  }

  void _onSubscriptionChanged() {
    final controller = SubscribeNotifier();
    final currentLocalSubscribed = _collectLocalSubscribedUserIds(controller);
    final newlySubscribed = currentLocalSubscribed.difference(
      _localSubscribedUserIds,
    );
    final newlyUnsubscribed = _localSubscribedUserIds.difference(
      currentLocalSubscribed,
    );

    if (newlySubscribed.isEmpty && newlyUnsubscribed.isEmpty) {
      return;
    }

    AppLogger.d(
      '🔔 [UserNotifier] Subscription delta — added: $newlySubscribed removed: $newlyUnsubscribed',
    );

    _localSubscribedUserIds = currentLocalSubscribed;
    _lastFetchTime = null;
    _subscriptionListDirty = true;

    unawaited(
      HiveService().evictCachedData(HiveService.userCacheBoxName, 'users_list'),
    );
    unawaited(CacheManager().invalidatePattern(ApiConstants.users));

    if (newlyUnsubscribed.isNotEmpty) {
      final beforeCount = state.users.length;
      final updatedUsers = state.users
          .where((user) => !newlyUnsubscribed.contains(user.userId))
          .toList();
      if (updatedUsers.length != beforeCount) {
        AppLogger.d(
          '⚡ [UserNotifier] Removed unsubscribed users -> total: ${updatedUsers.length}',
        );
        state = state.copyWith(users: updatedUsers);
      }
    }

    _scheduleSubscriptionRefresh();
  }

  void _scheduleSubscriptionRefresh() {
    _subscriptionDebounceTimer?.cancel();
    _subscriptionDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      AppLogger.d('🔄 [UserNotifier] Subscription refresh debounce fired');
      if (!state.isLoading) {
        unawaited(fetchUsers(reason: 'subscription_change'));
      } else {
        _needsRefreshAfterCurrent = true;
      }
    });
  }

  /// Call when the Messages tab becomes visible.
  Future<void> refreshOnTabVisible() async {
    AppLogger.d(
      '🔄 [UserNotifier] Tab visible — refreshing subscribed user list',
    );
    _lastFetchTime = null;
    await _invalidateUserListCaches();
    await fetchUsers(loadMore: false, reason: 'tab_visible');
  }

  /// Call when the Messages tab becomes visible to pick up subscription changes.
  Future<void> refreshIfSubscriptionDirty() async {
    if (!_subscriptionListDirty) return;
    AppLogger.d('🔄 [UserNotifier] Refreshing dirty subscription user list');
    _lastFetchTime = null;
    await _invalidateUserListCaches();
    await fetchUsers(loadMore: false, reason: 'subscription_change');
  }

  CancelToken _getCancelToken() {
    _cancelToken ??= CancelToken();
    return _cancelToken!;
  }

  void cancelActiveRequests() {
    _cancelToken?.cancel('Screen disposed');
    _cancelToken = null;
  }

  bool _shouldBypassCache(String reason) =>
      _cacheBypassReasons.contains(reason);

  Future<void> _invalidateUserListCaches() async {
    await HiveService().evictCachedData(
      HiveService.userCacheBoxName,
      'users_list',
    );
    await CacheManager().invalidatePattern(ApiConstants.users);
  }

  /// Message header should never show the logged-in user.
  List<UserEntity> _excludeSelf(List<UserEntity> users) {
    final selfId = _resolveSelfUserId();
    if (selfId == null || selfId.isEmpty) return users;
    return users.where((user) => user.userId.trim() != selfId).toList();
  }

  String? _resolveSelfUserId() {
    final authId = AuthStateManager().currentUserId?.trim();
    if (authId != null && authId.isNotEmpty) return authId;
    return ProfileIdentityService.instance.cachedLoggedInUserId?.trim();
  }

  List<UserEntity> _usersFromApi(Iterable<UserEntity> apiUsers) {
    return _excludeSelf(_cleanUsers(apiUsers));
  }

  void _syncSubscribedUsersFromApi(List<UserEntity> apiUsers) {
    SubscribeNotifier().syncSubscribedUsersFromApi(
      apiUsers.map(
        (user) => (
          userId: user.userId,
          username: user.username.isNotEmpty ? user.username : user.fullName,
        ),
      ),
    );
    _localSubscribedUserIds = apiUsers.map((user) => user.userId).toSet();
  }

  // Getters
  List<UserEntity> get users => state.users;
  bool get isLoading => state.isLoading;
  bool get isFetchingMore => state.isFetchingMore;
  bool get hasNext => state.hasNext;
  int get currentPage => state.currentPage;
  String? get errorMessage => state.errorMessage;
  bool get hasInitialized => state.hasInitialized;

  Future<void> fetchUsers({
    bool loadMore = false,
    String reason = 'initial',
  }) async {
    if (loadMore) {
      if (_loadMoreInFlight != null) {
        AppLogger.d(
          '⏳ [UserNotifier] Joining in-flight loadMore (reason=$reason)',
        );
        return _loadMoreInFlight!;
      }
      if (state.isFetchingMore || !state.hasNext) {
        AppLogger.d(
          '⏸️ [UserNotifier] loadMore skipped reason=$reason '
          'isFetchingMore=${state.isFetchingMore} hasNext=${state.hasNext}',
        );
        return;
      }

      final requestKey = 'page=${state.currentPage}';
      if (_lastLoadMoreKey == requestKey) {
        AppLogger.d(
          '⏸️ [UserNotifier] loadMore skipped duplicate params '
          'reason=$reason $requestKey',
        );
        return;
      }
      _lastLoadMoreKey = requestKey;

      final future = _runFetchUsers(loadMore: true, reason: reason);
      _loadMoreInFlight = future;
      try {
        return await future;
      } finally {
        if (identical(_loadMoreInFlight, future)) {
          _loadMoreInFlight = null;
        }
      }
    }

    if (_fetchInFlight != null) {
      AppLogger.d('⏳ [UserNotifier] Joining in-flight user fetch');
      return _fetchInFlight!;
    }

    final future = _runFetchUsers(loadMore: false, reason: reason);
    _fetchInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_fetchInFlight, future)) {
        _fetchInFlight = null;
      }
    }
  }

  Future<void> _runFetchUsers({
    required bool loadMore,
    required String reason,
  }) async {
    // 🚀 Cache-then-Network: Load from Hive offline storage first if we don't have users in memory
    final bypassCache = _shouldBypassCache(reason);
    if (!loadMore && state.users.isEmpty && !bypassCache) {
      final cachedData = HiveService().getCachedData(
        HiveService.userCacheBoxName,
        'users_list',
      );
      if (cachedData is List) {
        AppLogger.d(
          '📦 [UserNotifier] Cache HIT. Restoring users from Hive Cache first.',
        );
        try {
          final cachedUsers = _usersFromApi(
            cachedData.map(
              (e) =>
                  UserModel.fromJson(Map<String, dynamic>.from(e)).toEntity(),
            ),
          );
          state = state.copyWith(users: cachedUsers, hasInitialized: true);
        } catch (e) {
          AppLogger.d('🚨 [UserNotifier] Error parsing Hive cached users: $e');
        }
      }
    }

    // Check memory cache validity for initial load
    if (!loadMore &&
        !_shouldBypassCache(reason) &&
        !_subscriptionListDirty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration &&
        state.users.isNotEmpty) {
      AppLogger.d(
        '✅ [UserNotifier] Using cached users (age: ${DateTime.now().difference(_lastFetchTime!).inSeconds}s)',
      );
      return;
    }

    // Prevent duplicate calls
    if (loadMore && (state.isFetchingMore || !state.hasNext)) {
      AppLogger.d(
        '⏸️ [UserNotifier] Skipping fetchMore - isFetchingMore: ${state.isFetchingMore}, hasNext: ${state.hasNext}',
      );
      return;
    }

    if (!loadMore && state.isLoading) {
      AppLogger.d('⏸️ [UserNotifier] Skipping initial fetch - already loading');
      return;
    }

    AppLogger.d(
      '📡 [UserNotifier] fetch trigger=$reason page=${state.currentPage} loadMore=$loadMore',
    );

    // Set loading states immediately so scroll spam cannot slip through.
    if (loadMore) {
      state = state.copyWith(isFetchingMore: true, clearError: true);
    } else {
      _lastLoadMoreKey = null;
      state = state.copyWith(
        isLoading: true,
        currentPage: 1,
        hasNext: true,
        clearError: true,
        users: bypassCache ? const [] : null,
      );
    }

    if (!loadMore && bypassCache) {
      await _invalidateUserListCaches();
    }

    try {
      final repo = repository as UserRepositoryImpl;
      final response = await repo.fetchUsersPaginated(
        page: state.currentPage,
        cancelToken: _getCancelToken(),
        skipCache: bypassCache,
      );

      AppLogger.d(
        '📩 [UserNotifier] API response — returned ${response.users.length} users | hasNext: ${response.hasNext} | page: ${response.page}',
      );

      // Save initial page list to Hive cache
      if (!loadMore) {
        final usersJson = response.users
            .map(
              (e) => {
                'user_id': e.userId,
                'username': e.username,
                'full_name': e.fullName,
                'profile_picture': e.profilePicture,
              },
            )
            .toList();
        await HiveService().cacheData(
          HiveService.userCacheBoxName,
          'users_list',
          usersJson,
        );
      }

      if (response.users.isEmpty) {
        AppLogger.d('⚠️ [UserNotifier] API returned EMPTY user list');
      } else {
        final ids = response.users.map((u) => u.userId).take(5).toList();
        AppLogger.d('👤 [UserNotifier] userIDs (first 5): $ids');
      }

      // Update users list
      if (loadMore) {
        final beforeCount = state.users.length;
        final updatedUsers = _usersFromApi([
          ...state.users,
          ...response.users.map((m) => m.toEntity()),
        ]);
        AppLogger.d(
          '➕ [UserNotifier] Appended ${updatedUsers.length - beforeCount} users — total: ${updatedUsers.length}',
        );
        state = state.copyWith(
          users: updatedUsers,
          hasNext: response.hasNext,
          currentPage: response.hasNext ? response.page + 1 : state.currentPage,
        );
      } else {
        final apiUsers = _usersFromApi(response.users.map((m) => m.toEntity()));
        _syncSubscribedUsersFromApi(apiUsers);
        _lastFetchTime = DateTime.now();
        AppLogger.d(
          '🔄 [UserNotifier] API list applied with ${apiUsers.length} users (raw API=${response.users.length})',
        );
        state = state.copyWith(
          users: apiUsers,
          hasInitialized: true,
          hasNext: response.hasNext,
          currentPage: response.hasNext ? response.page + 1 : state.currentPage,
        );
      }

      _lastLoadMoreKey = null;

      AppLogger.d(
        '✅ [UserNotifier] Fetch complete — total: ${state.users.length} | hasNext: ${state.hasNext} | nextPage: ${state.currentPage}',
      );
      _subscriptionListDirty = false;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [UserNotifier] Request cancelled');
        return;
      }
      _lastLoadMoreKey = null;
      state = state.copyWith(errorMessage: e.toString());
      AppLogger.d('❌ [UserNotifier] Error: $e');
    } finally {
      // Clear loading states
      if (loadMore) {
        state = state.copyWith(isFetchingMore: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      AppLogger.d(
        '🏁 [UserNotifier] Loading states cleared - isLoading: ${state.isLoading}, isFetchingMore: ${state.isFetchingMore}',
      );

      if (!loadMore && _needsRefreshAfterCurrent) {
        _needsRefreshAfterCurrent = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          fetchUsers();
        });
      }
    }
  }

  List<UserEntity> _cleanUsers(Iterable<UserEntity> users) {
    final deduped = <String, UserEntity>{};

    for (final user in users) {
      final userId = user.userId.trim();
      final username = user.username.trim();
      final fullName = user.fullName.trim();
      if (userId.isEmpty || (username.isEmpty && fullName.isEmpty)) continue;
      deduped[userId] = user;
    }

    return deduped.values.toList();
  }

  // Method to reset pagination state (for pull-to-refresh)
  Future<void> refreshUsers() async {
    AppLogger.d('🔄 [UserNotifier] Refreshing users...');
    _lastFetchTime = null;
    await _invalidateUserListCaches();
    await fetchUsers(loadMore: false, reason: 'pull_to_refresh');
  }

  /// Reset provider state
  void reset() {
    _trackedAuthUserId = AuthStateManager().currentUserId;
    _clearUserListState();
    AppLogger.d('🔄 [UserNotifier] Provider state reset');
  }
}

final userNotifierProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);
