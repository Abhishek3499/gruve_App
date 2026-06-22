import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../domain/repository/user_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../data/models/user_model.dart';
import 'package:gruve_app/core/storage/hive_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/home/controllers/subscribe_controller.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository repository;
  UserProvider(this.repository) {
    AppLogger.d('🔥 UserProvider CONSTRUCTOR CALLED');
    _listenToSubscriptions();
  }

  Timer? _subscriptionDebounceTimer;
  bool _needsRefreshAfterCurrent = false;

  void _listenToSubscriptions() {
    SubscribeController().addListener(_onSubscriptionChanged);
  }

  void _onSubscriptionChanged() {
    AppLogger.d('🔔 [UserProvider] Subscription status changed in SubscribeController');
    _lastFetchTime = null; // Invalidate the memory cache!

    // ⚡ OPTIMISTIC UPDATE:
    bool changed = false;
    final controller = SubscribeController();
    final controllerUsers = controller.users;

    // 1. Remove unsubscribed users immediately
    final beforeCount = _users.length;
    _users.removeWhere((user) {
      final isSubscribed = controller.isUserSubscribed(user.userId);
      return !isSubscribed;
    });
    if (_users.length != beforeCount) {
      changed = true;
      AppLogger.d('⚡ [UserProvider] Optimistic Remove -> total users count: ${_users.length}');
    }

    // 2. Add newly subscribed users immediately
    for (final entry in controllerUsers.entries) {
      final userId = entry.key;
      final model = entry.value;

      if (model.isSubscribed) {
        final alreadyExists = _users.any((u) => u.userId == userId);
        if (!alreadyExists) {
          AppLogger.d('⚡ [UserProvider] Optimistic Add: ${model.username}');
          _users.add(UserEntity(
            userId: userId,
            username: model.username,
            fullName: model.username, // Fallback to username
          ));
          changed = true;
        }
      }
    }

    if (changed) {
      notifyListeners();
    }

    // Trigger background fetch if we have already initialized, so the UI updates immediately
    if (_hasInitialized) {
      _subscriptionDebounceTimer?.cancel();
      _subscriptionDebounceTimer = Timer(const Duration(milliseconds: 750), () {
        if (!_isLoading) {
          AppLogger.d('🔄 [UserProvider] Subscription change debounce completed -> fetching updated users list');
          fetchUsers();
        } else {
          AppLogger.d('🔄 [UserProvider] Subscription change debounce completed but already loading -> scheduling refresh');
          _needsRefreshAfterCurrent = true;
        }
      });
    }
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
  static const _cacheValidDuration = Duration(minutes: 2);

  // Getters
  List<UserEntity> get users => _users;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasNext => _hasNext;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;
  bool get hasInitialized => _hasInitialized;

  Future<void> fetchUsers({bool loadMore = false}) async {
    if (_fetchInFlight != null && !loadMore) {
      AppLogger.d('⏳ [UserProvider] Joining in-flight user fetch');
      return _fetchInFlight!;
    }

    final future = _runFetchUsers(loadMore: loadMore);
    if (!loadMore) _fetchInFlight = future;
    try {
      return await future;
    } finally {
      if (!loadMore && identical(_fetchInFlight, future)) {
        _fetchInFlight = null;
      }
    }
  }

  Future<void> _runFetchUsers({bool loadMore = false}) async {
    // 🚀 Cache-then-Network: Load from Hive offline storage first if we don't have users in memory
    if (!loadMore && _users.isEmpty) {
      final cachedData = HiveService().getCachedData(
        HiveService.userCacheBoxName,
        'users_list',
      );
      if (cachedData is List) {
        AppLogger.d('📦 [UserProvider] Cache HIT. Restoring users from Hive Cache first.');
        try {
          _users = cachedData
              .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)).toEntity())
              .toList();
          _hasInitialized = true;
          notifyListeners();
        } catch (e) {
          AppLogger.d('🚨 [UserProvider] Error parsing Hive cached users: $e');
        }
      }
    }

    // Check memory cache validity for initial load
    if (!loadMore &&
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
      '🚀 [UserProvider] Fetching page: $_currentPage (loadMore: $loadMore)',
    );

    // Set loading states
    if (loadMore) {
      _isFetchingMore = true;
    } else {
      _isLoading = true;
      _currentPage = 1; // Reset page for initial load
      _hasNext = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final repo = repository as UserRepositoryImpl;
      final response = await repo.fetchUsersPaginated(
        page: _currentPage,
        cancelToken: _getCancelToken(),
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
        _users = _cleanUsers([
          ..._users,
          ...response.users.map((m) => m.toEntity()),
        ]);
        AppLogger.d(
          '➕ [UserProvider] Appended ${_users.length - beforeCount} users — total: ${_users.length}',
        );
      } else {
        _users = _cleanUsers(response.users.map((m) => m.toEntity()));
        _lastFetchTime = DateTime.now();
        _hasInitialized = true;
        AppLogger.d(
          '🔄 [UserProvider] Replaced list with ${_users.length} users',
        );
      }

      // Update pagination state
      _hasNext = response.hasNext;
      if (response.hasNext) {
        _currentPage = response.page + 1;
      }

      AppLogger.d(
        '✅ [UserProvider] Fetch complete — total: ${_users.length} | hasNext: $_hasNext | nextPage: $_currentPage',
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.d('🚫 [UserProvider] Request cancelled');
        return;
      }
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
    _lastFetchTime = null; // Clear cache
    await fetchUsers(loadMore: false);
  }

  /// Reset provider state
  void reset() {
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
    AppLogger.d('🔄 [UserProvider] Provider state reset');
    notifyListeners();
  }

  @override
  void dispose() {
    SubscribeController().removeListener(_onSubscriptionChanged);
    _subscriptionDebounceTimer?.cancel();
    cancelActiveRequests();
    AppLogger.d('🗑️ [UserProvider] Disposed');
    super.dispose();
  }
}
