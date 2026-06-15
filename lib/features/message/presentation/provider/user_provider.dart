import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repository/user_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repository/user_repository_impl.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository repository;
  UserProvider(this.repository) {
    AppLogger.d('🔥 UserProvider CONSTRUCTOR CALLED');
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
    // Check cache validity for initial load
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
    cancelActiveRequests();
    AppLogger.d('🗑️ [UserProvider] Disposed');
    super.dispose();
  }
}
