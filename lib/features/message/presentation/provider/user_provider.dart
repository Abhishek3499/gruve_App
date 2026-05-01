import 'package:flutter/foundation.dart';
import '../../domain/repository/user_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../data/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository repository;
  UserProvider(this.repository) {
    // Auto-fetch users when provider is created
    _initializeUsers();
  }

  List<UserEntity> _users = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasNext = true;
  int _currentPage = 1;
  String? _errorMessage;
  bool _hasInitialized = false;

  // Getters
  List<UserEntity> get users => _users;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasNext => _hasNext;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;

  Future<void> _initializeUsers() async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    
    debugPrint('🔄 [UserProvider] Initializing - auto-fetching users...');
    await fetchUsers();
  }

  Future<void> fetchUsers({bool loadMore = false}) async {
    // Prevent duplicate calls
    if (loadMore && (_isFetchingMore || !_hasNext)) {
      debugPrint('⏸️ [UserProvider] Skipping fetchMore - isFetchingMore: $_isFetchingMore, hasNext: $_hasNext');
      return;
    }

    if (!loadMore && _isLoading) {
      debugPrint('⏸️ [UserProvider] Skipping initial fetch - already loading');
      return;
    }

    debugPrint('🚀 [UserProvider] Fetching page: $_currentPage (loadMore: $loadMore)');

    // Set loading states
    if (loadMore) {
      _isFetchingMore = true;
    } else {
      _isLoading = true;
      _currentPage = 1; // Reset page for initial load
      _users.clear(); // Clear existing data for fresh load
      _hasNext = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final repo = repository as UserRepositoryImpl;
      final response = await repo.fetchUsersPaginated(page: _currentPage);
      
      // Update users list
      if (loadMore) {
        _users.addAll(response.users.map((m) => m.toEntity()));
        debugPrint('➕ [UserProvider] Appended ${response.users.length} users to existing list');
      } else {
        _users = response.users.map((m) => m.toEntity()).toList();
        debugPrint('🔄 [UserProvider] Replaced list with ${response.users.length} users');
      }

      // Update pagination state
      _hasNext = response.hasNext;
      if (response.hasNext) {
        _currentPage = response.page + 1;
      }

      debugPrint('📦 [UserProvider] Users fetched: ${response.users.length}');
      debugPrint('➡️ [UserProvider] Has next: $_hasNext');
      debugPrint('👥 [UserProvider] Total users: ${_users.length}');
      debugPrint('📄 [UserProvider] Current page: ${response.page}, Next page: $_currentPage');

    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ [UserProvider] Error: $e');
    } finally {
      // Clear loading states
      if (loadMore) {
        _isFetchingMore = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // Method to reset pagination state (for pull-to-refresh)
  Future<void> refreshUsers() async {
    debugPrint('🔄 [UserProvider] Refreshing users...');
    await fetchUsers(loadMore: false);
  }

  @override
  void dispose() {
    debugPrint('🗑️ [UserProvider] Disposed');
    super.dispose();
  }
}
