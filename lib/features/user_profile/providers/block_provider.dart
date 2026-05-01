import 'package:flutter/foundation.dart';
import '../api/block_api_service.dart';
import '../../profile_menu_drawer/models/blocked/blocked_user_model.dart';

class BlockProvider extends ChangeNotifier {
  final BlockApiService _apiService = BlockApiService();

  // State for each user (userId -> isBlocked)
  final Map<String, bool> _blockStates = {};
  
  // Loading state for each user
  final Map<String, bool> _loadingStates = {};

  // Blocked users list
  List<BlockedUserModel> _blockedUsers = [];
  bool _isLoadingList = false;

  List<BlockedUserModel> get blockedUsers => _blockedUsers;
  bool get isLoadingList => _isLoadingList;

  void _log(String message) {
    debugPrint('🔒 [BlockProvider] $message');
  }

  /// Fetch blocked users list
  Future<void> fetchBlockedUsers() async {
    if (_isLoadingList) {
      _log('⚠️ FETCH BLOCKED - Already loading');
      return;
    }

    _log('🔄 FETCH START - blocked users list');
    _isLoadingList = true;
    notifyListeners();

    try {
      _blockedUsers = await _apiService.fetchBlockedUsers();
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

  /// Toggle block/unblock with optimistic UI update and rollback
  Future<void> toggleBlockUser(String userId, {bool refreshList = false}) async {
    // Guard: Prevent multiple simultaneous API calls
    if (_loadingStates[userId] == true) {
      _log('⚠️ TOGGLE BLOCKED - Already loading for userId=$userId');
      return;
    }

    _log('🔄 TOGGLE START - userId=$userId');
    
    // Store previous state for rollback
    final previousState = _blockStates[userId] ?? false;
    _log('💾 Previous state: $previousState');

    // Optimistic UI update
    _loadingStates[userId] = true;
    _blockStates[userId] = !previousState;
    _log('🔁 OPTIMISTIC UPDATE - New state: ${_blockStates[userId]}');
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
          await fetchBlockedUsers();
        }
      } else {
        // Rollback on failure
        _blockStates[userId] = previousState;
        _log('❌ ROLLBACK - API returned success=false');
      }
    } catch (e) {
      // Rollback on error
      _blockStates[userId] = previousState;
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
    debugPrint('🔄 [BlockProvider] Resetting block data...');
    _blockStates.clear();
    _loadingStates.clear();
    _blockedUsers.clear();
    _isLoadingList = false;
    notifyListeners();
    debugPrint('✅ [BlockProvider] Block data reset complete');
  }

  /// Clear all states (legacy method)
  void clearAll() {
    _blockStates.clear();
    _loadingStates.clear();
    notifyListeners();
  }
}
