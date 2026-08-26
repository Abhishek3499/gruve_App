import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
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
import 'package:gruve_app/features/home/presentation/controller/subscribe_controller.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository repository;
  UserProvider(this.repository) {
    AppLogger.d('🔥 UserProvider CONSTRUCTOR CALLED');
    _trackedAuthUserId = AuthStateManager().currentUserId;
    _localSubscribedUserIds =
        _collectLocalSubscribedUserIds(SubscribeController());
    _listenToSubscriptions();
    AuthStateManager().addListener(_onAuthStateChanged);
  }

  Timer? _subscriptionDebounceTimer;
  bool _needsRefreshAfterCurrent = false;
  bool _subscriptionListDirty = false;
  Set<String> _localSubscribedUserIds = {};
  String? _trackedAuthUserId;

  void _listenToSubscriptions() {
    SubscribeController().addListener(_onSubscriptionChanged);
  }

  void _onAuthStateChanged() {
    final authUserId = AuthStateManager().currentUserId;
    if (authUserId == _trackedAuthUserId) return;

    AppLogger.d(
      '🔄 [UserProvider] Auth user changed $_trackedAuthUserId -> $authUserId, clearing list',
    );
    _trackedAuthUserId = authUserId;
    _clearUserListState();
    notifyListeners();
  }

  void _clearUserListState() {
    _subscriptionDebounceTimer?.cancel();
    _needsRefreshAfterCurrent = false;
    _users.clear();
    _isLoading = false;
    _isFetchingMore = false;
    _hasNext = true;
    _currentPage = 1;
    _errorMessage = null;
    _hasInitialized = false;
    _lastFetchTime = null;
    _fetchInFlight = null;
    _loadMoreInFlight = null;
    _lastLoadMoreKey = null;
    _subscriptionListDirty = false;
    _localSubscribedUserIds = {};
  }

  Set<String> _collectLocalSubscribedUserIds(SubscribeController controller) {
    return controller.users.entries
        .where((e) => e.value.isSubscribed)
        .map((e) => e.key)
        .toSet();
  }

  void _onSubscriptionChanged() {
    final controller = SubscribeController();
    final currentLocalSubscribed = _collectLocalSubscribedUserIds(controller);
    final newlySubscribed =
        currentLocalSubscribed.difference(_localSubscribedUserIds);
    final newlyUnsubscribed =
        _localSubscribedUserIds.difference(currentLocalSubscribed);

    if (newlySubscribed.isEmpty && newlyUnsubscribed.isEmpty) {
      return;
    }

    AppLogger.d(
      '🔔 [UserProvider] Subscription delta — added: $newlySubscribed removed: $newlyUnsubscribed',
    );

    _localSubscribedUserIds = currentLocalSubscribed;
    _lastFetchTime = null;
    _subscriptionListDirty = true;

    unawaited(HiveService().evictCachedData(
      HiveService.userCacheBoxName,
      'users_list',
    ));
    unawaited(CacheManager().invalidatePattern(ApiConstants.users));

    var changed = false;

    if (newlyUnsubscribed.isNotEmpty) {
      final beforeCount = _users.length;
      _users.removeWhere((user) => newlyUnsubscribed.contains(user.userId));
      if (_users.length != beforeCount) {
        changed = true;
        AppLogger.d(
          '⚡ [UserProvider] Removed unsubscribed users -> total: ${_users.length}',
        );
      }
    }

    if (changed) {
      notifyListeners();
    }

    _scheduleSubscriptionRefresh();
  }

  void _scheduleSubscriptionRefresh() {
    _subscriptionDebounceTimer?.cancel();
    _subscriptionDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      AppLogger.d('🔄 [UserProvider] Subscription refresh debounce fired');
      if (!_isLoading) {
        unawaited(fetchUsers(reason: 'subscription_change'));
      } else {
        _needsRefreshAfterCurrent = true;
      }
    });
  }

  /// Call when the Messages tab becomes visible.
  Future<void> refreshOnTabVisible() async {
    AppLogger.d('🔄 [UserProvider] Tab visible — refreshing subscribed user list');
    _lastFetchTime = null;
    await _invalidateUserListCaches();
    await fetchUsers(loadMore: false, reason: 'tab_visible');
  }

  /// Call when the Messages tab becomes visible to pick up subscription changes.
  Future<void> refreshIfSubscriptionDirty() async {
    if (!_subscriptionListDirty) return;
    AppLogger.d('🔄 [UserProvider] Refreshing dirty subscription user list');
    _lastFetchTime = null;
    await _invalidateUserListCaches();
    await fetchUsers(loadMore: false, reason: 'subscription_change');
  }

  List<UserEntity> _users = [];
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
  bool _isFetchingMore = false;
  bool _hasNext = true;
  int _currentPage = 1;
  String? _errorMessage;
  bool _hasInitialized = false;
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

  bool _shouldBypassCache(String reason) => _cacheBypassReasons.contains(reason);

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
    SubscribeController().syncSubscribedUsersFromApi(
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
  List<UserEntity> get users => _users;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasNext => _hasNext;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;
  bool get hasInitialized => _hasInitialized;

  Future<void> fetchUsers({bool loadMore = false, String reason = 'initial'}) async {
    if (loadMore) {
      if (_loadMoreInFlight != null) {
        AppLogger.d('⏳ [UserProvider] Joining in-flight loadMore (reason=$reason)');
        return _loadMoreInFlight!;
      }
      if (_isFetchingMore || !_hasNext) {
        AppLogger.d(
          '⏸️ [UserProvider] loadMore skipped reason=$reason '
          'isFetchingMore=$_isFetchingMore hasNext=$_hasNext',
        );
        return;
      }

      final requestKey = 'page=$_currentPage';
      if (_lastLoadMoreKey == requestKey) {
        AppLogger.d(
          '⏸️ [UserProvider] loadMore skipped duplicate params '
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
      AppLogger.d('⏳ [UserProvider] Joining in-flight user fetch');
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
    if (!loadMore && _users.isEmpty && !bypassCache) {
      final cachedData = HiveService().getCachedData(
        HiveService.userCacheBoxName,
        'users_list',
      );
      if (cachedData is List) {
        AppLogger.d('📦 [UserProvider] Cache HIT. Restoring users from Hive Cache first.');
        try {
          _users = _usersFromApi(
            cachedData
                .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)).toEntity()),
          );
          _hasInitialized = true;
          notifyListeners();
        } catch (e) {
          AppLogger.d('🚨 [UserProvider] Error parsing Hive cached users: $e');
        }
      }
    }

    // Check memory cache validity for initial load
    if (!loadMore &&
        !_shouldBypassCache(reason) &&
        !_subscriptionListDirty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration &&
        _users.isNotEmpty) {
      AppLogger.d(
        '✅ [UserProvider] Using cached users (age: ${DateTime.now().difference(_lastFetchTime!).inSeconds}s)',
      );
      return;
    }

    // Prevent duplicate calls
    if (loadMore && (_isFetchingMore || !_hasNext)) {
      AppLogger.d(
        '⏸️ [UserProvider] Skipping fetchMore - isFetchingMore: $_isFetchingMore, hasNext: $_hasNext',
      );
      return;
    }

    if (!loadMore && _isLoading) {
      AppLogger.d('⏸️ [UserProvider] Skipping initial fetch - already loading');
      return;
    }

    AppLogger.d(
      '📡 [UserProvider] fetch trigger=$reason page=$_currentPage loadMore=$loadMore',
    );

    // Set loading states immediately so scroll spam cannot slip through.
    if (loadMore) {
      _isFetchingMore = true;
    } else {
      _isLoading = true;
      _currentPage = 1;
      _hasNext = true;
      _lastLoadMoreKey = null;
      if (bypassCache) {
        _users.clear();
      }
    }
    _errorMessage = null;
    notifyListeners();

    if (!loadMore && bypassCache) {
      await _invalidateUserListCaches();
    }

    try {
      final repo = repository as UserRepositoryImpl;
      final response = await repo.fetchUsersPaginated(
        page: _currentPage,
        cancelToken: _getCancelToken(),
        skipCache: bypassCache,
      );

      AppLogger.d(
        '📩 [UserProvider] API response — returned ${response.users.length} users | hasNext: ${response.hasNext} | page: ${response.page}',
      );

      // Save initial page list to Hive cache
      if (!loadMore) {
        final usersJson = response.users.map((e) => {
          'user_id': e.userId,
          'username': e.username,
          'full_name': e.fullName,
          'profile_picture': e.profilePicture,
        }).toList();
        await HiveService().cacheData(
          HiveService.userCacheBoxName,
          'users_list',
          usersJson,
        );
      }

      if (response.users.isEmpty) {
        AppLogger.d('⚠️ [UserProvider] API returned EMPTY user list');
      } else {
        final ids = response.users.map((u) => u.userId).take(5).toList();
        AppLogger.d('👤 [UserProvider] userIDs (first 5): $ids');
      }

      // Update users list
      if (loadMore) {
        final beforeCount = _users.length;
        _users = _usersFromApi([
          ..._users,
          ...response.users.map((m) => m.toEntity()),
        ]);
        AppLogger.d(
          '➕ [UserProvider] Appended ${_users.length - beforeCount} users — total: ${_users.length}',
        );
      } else {
        final apiUsers = _usersFromApi(response.users.map((m) => m.toEntity()));
        _users = apiUsers;
        _syncSubscribedUsersFromApi(apiUsers);
        _lastFetchTime = DateTime.now();
        _hasInitialized = true;
        AppLogger.d(
          '🔄 [UserProvider] API list applied with ${_users.length} users (raw API=${response.users.length})',
        );
      }

      // Update pagination state
      _hasNext = response.hasNext;
      if (response.hasNext) {
        _currentPage = response.page + 1;
      }
      _lastLoadMoreKey = null;

      AppLogger.d(
        '✅ [UserProvider] Fetch complete — total: ${_users.length} | hasNext: $_hasNext | nextPage: $_currentPage',
      );
      _subscriptionListDirty = false;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [UserProvider] Request cancelled');
        return;
      }
      _lastLoadMoreKey = null;
      _errorMessage = e.toString();
      AppLogger.d('❌ [UserProvider] Error: $e');
    } finally {
      // Clear loading states
      if (loadMore) {
        _isFetchingMore = false;
      } else {
        _isLoading = false;
      }

      AppLogger.d(
        '🏁 [UserProvider] Loading states cleared - isLoading: $_isLoading, isFetchingMore: $_isFetchingMore',
      );
      notifyListeners();

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
    AppLogger.d('🔄 [UserProvider] Refreshing users...');
    _lastFetchTime = null;
    await _invalidateUserListCaches();
    await fetchUsers(loadMore: false, reason: 'pull_to_refresh');
  }

  /// Reset provider state
  void reset() {
    _trackedAuthUserId = AuthStateManager().currentUserId;
    _clearUserListState();
    AppLogger.d('🔄 [UserProvider] Provider state reset');
    notifyListeners();
  }

  @override
  void dispose() {
    AuthStateManager().removeListener(_onAuthStateChanged);
    SubscribeController().removeListener(_onSubscriptionChanged);
    _subscriptionDebounceTimer?.cancel();
    cancelActiveRequests();
    AppLogger.d('🗑️ [UserProvider] Disposed');
    super.dispose();
  }
}
