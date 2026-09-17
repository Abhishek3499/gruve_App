import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/user_profile/data/datasource/block_api_service.dart';
import 'package:gruve_app/features/blocked/domain/entities/blocked_user_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Immutable state for [BlockNotifier]: per-user block/loading flags plus
/// the cached blocked-users list.
@immutable
class BlockState {
  const BlockState({
    this.blockStates = const {},
    this.loadingStates = const {},
    this.blockedUsers = const [],
    this.isLoadingList = false,
  });

  final Map<String, bool> blockStates;
  final Map<String, bool> loadingStates;
  final List<BlockedUserModel> blockedUsers;
  final bool isLoadingList;

  bool isBlocked(String userId) => blockStates[userId] ?? false;
  bool isLoading(String userId) => loadingStates[userId] ?? false;

  BlockState copyWith({
    Map<String, bool>? blockStates,
    Map<String, bool>? loadingStates,
    List<BlockedUserModel>? blockedUsers,
    bool? isLoadingList,
  }) {
    return BlockState(
      blockStates: blockStates ?? this.blockStates,
      loadingStates: loadingStates ?? this.loadingStates,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      isLoadingList: isLoadingList ?? this.isLoadingList,
    );
  }
}

class BlockNotifier extends Notifier<BlockState> {
  final BlockApiService _apiService = BlockApiService();

  Future<void>? _blockedUsersFetchFuture;
  DateTime? _lastBlockedUsersFetchAt;
  static const _blockedUsersCacheTtl = Duration(minutes: 5);

  @override
  BlockState build() => const BlockState();

  List<BlockedUserModel> get blockedUsers =>
      List.unmodifiable(state.blockedUsers);
  bool get isLoadingList => state.isLoadingList;

  void _log(String message) {
    AppLogger.d('🔒 [BlockNotifier] $message');
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
    state = state.copyWith(isLoadingList: true);

    try {
      final blockedUsers = await _apiService.fetchBlockedUsers(
        forceRefresh: true,
      );
      _lastBlockedUsersFetchAt = DateTime.now();
      state = state.copyWith(
        blockedUsers: blockedUsers,
        blockStates: _syncedBlockStates(blockedUsers),
      );
      _log('✅ DATA LOADED - ${blockedUsers.length} users');
    } catch (e) {
      _log('❌ ERROR - Failed to fetch blocked users: $e');
      state = state.copyWith(blockedUsers: const []);
      rethrow;
    } finally {
      state = state.copyWith(isLoadingList: false);
      _log('🏁 FETCH END');
    }
  }

  /// Get block state for a specific user
  bool isBlocked(String userId) => state.isBlocked(userId);

  /// Get loading state for a specific user
  bool isLoading(String userId) => state.isLoading(userId);

  /// Initialize block state for a user (from API data)
  void setBlockState(String userId, bool isBlocked) {
    _log('📌 setBlockState userId=$userId, isBlocked=$isBlocked');
    state = state.copyWith(
      blockStates: {...state.blockStates, userId: isBlocked},
    );
  }

  /// Toggle block/unblock. When [optimistic] is false, local block state updates only after the server responds (backend is source of truth).
  Future<void> toggleBlockUser(
    String userId, {
    bool refreshList = false,
    bool optimistic = false,
  }) async {
    // Guard: Prevent multiple simultaneous API calls
    if (state.isLoading(userId)) {
      _log('⚠️ TOGGLE BLOCKED - Already loading for userId=$userId');
      return;
    }

    _log('🔄 TOGGLE START - userId=$userId optimistic=$optimistic');

    // Store previous state for rollback
    final previousState = state.isBlocked(userId);
    _log('💾 Previous state: $previousState');

    state = state.copyWith(
      loadingStates: {...state.loadingStates, userId: true},
      blockStates: optimistic
          ? {...state.blockStates, userId: !previousState}
          : state.blockStates,
    );
    if (optimistic) {
      _log('🔁 OPTIMISTIC UPDATE - New state: ${state.isBlocked(userId)}');
    }

    try {
      // API call
      final response = await _apiService.toggleBlockUser(userId);

      if (response.success && response.data != null) {
        // Update with actual server state
        state = state.copyWith(
          blockStates: {...state.blockStates, userId: response.data!.isBlocked},
        );
        _log('✅ STATE UPDATED - Server confirmed: ${state.isBlocked(userId)}');

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
          state = state.copyWith(
            blockStates: {...state.blockStates, userId: previousState},
          );
        }
        _log('❌ ROLLBACK - API returned success=false');
        throw StateError('Block toggle rejected by server');
      }
    } catch (e) {
      if (optimistic) {
        state = state.copyWith(
          blockStates: {...state.blockStates, userId: previousState},
        );
      }
      _log('❌ ROLLBACK - Error occurred: $e');
      rethrow;
    } finally {
      state = state.copyWith(
        loadingStates: {...state.loadingStates, userId: false},
      );
      _log('🏁 TOGGLE END - Final state: ${state.isBlocked(userId)}');
    }
  }

  /// Clear state for a user (useful when navigating away)
  void clearUserState(String userId) {
    final blockStates = {...state.blockStates}..remove(userId);
    final loadingStates = {...state.loadingStates}..remove(userId);
    state = state.copyWith(
      blockStates: blockStates,
      loadingStates: loadingStates,
    );
  }

  /// Reset all block data on logout
  void reset() {
    AppLogger.d('🔄 [BlockNotifier] Resetting block data...');
    _blockedUsersFetchFuture = null;
    _lastBlockedUsersFetchAt = null;
    state = const BlockState();
    AppLogger.d('✅ [BlockNotifier] Block data reset complete');
  }

  /// Clear all states (legacy method)
  void clearAll() {
    state = state.copyWith(blockStates: const {}, loadingStates: const {});
  }

  Map<String, bool> _syncedBlockStates(List<BlockedUserModel> blockedUsers) {
    final blockedIds = blockedUsers.map((user) => user.userId).toSet();
    final updated = {...state.blockStates};

    for (final userId in updated.keys.toList()) {
      updated[userId] = blockedIds.contains(userId);
    }

    for (final userId in blockedIds) {
      updated[userId] = true;
    }

    return updated;
  }

  Future<void> _refreshSingleStateFromBackend(String userId) async {
    await fetchBlockedUsers(forceRefresh: true);
    state = state.copyWith(
      blockStates: {
        ...state.blockStates,
        userId: state.blockedUsers.any((user) => user.userId == userId),
      },
    );
  }
}

final blockNotifierProvider = NotifierProvider<BlockNotifier, BlockState>(
  BlockNotifier.new,
);
