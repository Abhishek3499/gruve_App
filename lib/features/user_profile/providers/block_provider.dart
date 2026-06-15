import '../api/block_api_service.dart';
import 'package:flutter/foundation.dart';
import '../../profile_menu_drawer/models/blocked/blocked_user_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class BlockProvider extends ChangeNotifier {
  final BlockApiService _apiService = BlockApiService();

  // State for each user (userId -> isBlocked)
  final Map<String, bool> _blockStates = {};
  
  // Loading state for each user
  final Map<String, bool> _loadingStates = {};

  // Blocked users list
  List<BlockedUserModel> _blockedUsers = [];
  bool _isLoadingList = false;
  Future<void>? _blockedUsersFetchFuture;
  DateTime? _lastBlockedUsersFetchAt;
  static const _blockedUsersCacheTtl = Duration(minutes: 5);

  List<BlockedUserModel> get blockedUsers => List.unmodifiable(_blockedUsers);
  bool get isLoadingList => _isLoadingList;

  void _log(String message) {
    AppLogger.d('🔒 [BlockProvider] $message');
  }

  /// Fetch blocked users list. Concurrent callers without [forceRefresh] share one in-flight request.
  /// When [forceRefresh] is true (e.g. after a successful block toggle), any prior in-flight fetch is
  /// awaited first, then a new request runs so the list matches the backend after the mutation.
  Future<void> fetchBlockedUsers({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastBlockedUsersFetchAt != null &&
        DateTime.now().difference(_lastBlockedUsersFetchAt!) <
            _blockedUsersCacheTtl) {
      _log('✅ FETCH BLOCKED - Using cached blocked users list');
      return;
    }

    if (_blockedUsersFetchFuture != null) {
      _log('⚠️ FETCH BLOCKED - Joining in-flight request');
      try {
        await _blockedUsersFetchFuture!;
      } catch (_) {}
      if (!forceRefresh) return;
    }

    _blockedUsersFetchFuture = _runFetchBlockedUsers();
    try {
      await _blockedUsersFetchFuture!;
    } finally {
      _blockedUsersFetchFuture = null;
    }
  }

  Future<void> _runFetchBlockedUsers() async {
    _log('🔄 FETCH START - blocked users list');
    _isLoadingList = true;
    notifyListeners();

    try {
      _blockedUsers = await _apiService.fetchBlockedUsers(forceRefresh: true);
      _lastBlockedUsersFetchAt = DateTime.now();
      _syncBlockStatesFromList();
      _log('✅ DATA LOADED - ${_blockedUsers.length} users');
    } catch (e) {
      _log('❌ ERROR - Failed to fetch blocked users: $e');
      _blockedUsers = [];
      rethrow;
    } finally {
      _isLoadingList = false;
      notifyListeners();
      _log('🏁 FETCH END');
    }
  }

  /// Get block state for a specific user
  bool isBlocked(String userId) {
    return _blockStates[userId] ?? false;
  }

  /// Get loading state for a specific user
  bool isLoading(String userId) {
    return _loadingStates[userId] ?? false;
  }

  /// Initialize block state for a user (from API data)
  void setBlockState(String userId, bool isBlocked) {
    _log('📌 setBlockState userId=$userId, isBlocked=$isBlocked');
    _blockStates[userId] = isBlocked;
    notifyListeners();
  }

  /// Toggle block/unblock. When [optimistic] is false, local block state updates only after the server responds (backend is source of truth).
  Future<void> toggleBlockUser(
    String userId, {
    bool refreshList = false,
    bool optimistic = false,
  }) async {
    // Guard: Prevent multiple simultaneous API calls
    if (_loadingStates[userId] == true) {
      _log('⚠️ TOGGLE BLOCKED - Already loading for userId=$userId');
      return;
    }

    _log('🔄 TOGGLE START - userId=$userId optimistic=$optimistic');

    // Store previous state for rollback
    final previousState = _blockStates[userId] ?? false;
    _log('💾 Previous state: $previousState');

    _loadingStates[userId] = true;
    if (optimistic) {
      _blockStates[userId] = !previousState;
      _log('🔁 OPTIMISTIC UPDATE - New state: ${_blockStates[userId]}');
    }
    notifyListeners();

    try {
      // API call
      final response = await _apiService.toggleBlockUser(userId);

      if (response.success && response.data != null) {
        // Update with actual server state
        _blockStates[userId] = response.data!.isBlocked;
        _log('✅ STATE UPDATED - Server confirmed: ${_blockStates[userId]}');

        // Refresh blocked users list if requested
        if (refreshList) {
          _log('🔄 Refreshing blocked users list...');
          await fetchBlockedUsers(forceRefresh: true);
        } else {
          await _refreshSingleStateFromBackend(userId);
        }
      } else {
        // Rollback on failure (only if we changed local state optimistically)
        if (optimistic) {
          _blockStates[userId] = previousState;
        }
        _log('❌ ROLLBACK - API returned success=false');
        throw StateError('Block toggle rejected by server');
      }
    } catch (e) {
      if (optimistic) {
        _blockStates[userId] = previousState;
      }
      _log('❌ ROLLBACK - Error occurred: $e');
      rethrow;
    } finally {
      _loadingStates[userId] = false;
      notifyListeners();
      _log('🏁 TOGGLE END - Final state: ${_blockStates[userId]}');
    }
  }

  /// Clear state for a user (useful when navigating away)
  void clearUserState(String userId) {
    _blockStates.remove(userId);
    _loadingStates.remove(userId);
    notifyListeners();
  }

  /// Reset all block data on logout
  void reset() {
    AppLogger.d('🔄 [BlockProvider] Resetting block data...');
    _blockStates.clear();
    _loadingStates.clear();
    _blockedUsers.clear();
    _isLoadingList = false;
    _blockedUsersFetchFuture = null;
    _lastBlockedUsersFetchAt = null;
    notifyListeners();
    AppLogger.d('✅ [BlockProvider] Block data reset complete');
  }

  /// Clear all states (legacy method)
  void clearAll() {
    _blockStates.clear();
    _loadingStates.clear();
    notifyListeners();
  }

  void _syncBlockStatesFromList() {
    final blockedIds = _blockedUsers.map((user) => user.userId).toSet();

    for (final userId in _blockStates.keys.toList()) {
      _blockStates[userId] = blockedIds.contains(userId);
    }

    for (final userId in blockedIds) {
      _blockStates[userId] = true;
    }
  }

  Future<void> _refreshSingleStateFromBackend(String userId) async {
    await fetchBlockedUsers(forceRefresh: true);
    _blockStates[userId] = _blockedUsers.any((user) => user.userId == userId);
  }
}
