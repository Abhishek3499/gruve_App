import 'package:flutter/material.dart';
import 'package:gruve_app/features/search/data/datasource/user_search_service.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/app_navigator.dart';

class PostShareProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  final Set<SearchUser> _selectedUsers = {};
  bool _isSending = false;

  // Search-related states managed by Provider
  final DebouncedUserSearch _userSearch = DebouncedUserSearch();
  List<SearchUser> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  String _searchQuery = '';

  Set<SearchUser> get selectedUsers => _selectedUsers;
  bool get isSending => _isSending;

  List<SearchUser> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  String get searchQuery => _searchQuery;

  void toggleUser(SearchUser user) {
    if (_isSending) return;

    final exists = _selectedUsers.any((u) => u.id == user.id);
    if (exists) {
      _selectedUsers.removeWhere((u) => u.id == user.id);
    } else {
      _selectedUsers.add(user);
    }
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _searchError = null;

    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      _userSearch.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _userSearch.search(
      query,
      onResults: (users) {
        _searchResults = users;
        _isSearching = false;
        notifyListeners();
      },
      onError: (error) {
        _searchResults = [];
        _isSearching = false;
        _searchError = 'Unable to search users right now';
        notifyListeners();
      },
    );
  }

  void clearSelection() {
    _selectedUsers.clear();
    _isSending = false;
    _searchResults = [];
    _isSearching = false;
    _searchError = null;
    _searchQuery = '';
    _userSearch.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _userSearch.dispose();
    super.dispose();
  }

  Future<bool> sharePost(String postId) async {
    if (_selectedUsers.isEmpty || _isSending) return false;

    _isSending = true;
    notifyListeners();

    final recipientIds = _selectedUsers.map((u) => u.id).toList();
    final names = _selectedUsers.map((u) => u.username).join(', ');

    try {
      final success = await _postService.sharePost(
        postId: postId,
        recipientUserIds: recipientIds,
      );

      if (success) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Shared successfully with $names'),
            backgroundColor: const Color(0xFF7A1FA2),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        clearSelection();
        return true;
      } else {
        throw Exception('Share request failed');
      }
    } catch (e) {
      AppLogger.d('❌ [PostShareProvider] Error sharing post: $e');
      _isSending = false;
      notifyListeners();
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Failed to share post. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }
}
