import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/search/data/datasource/user_search_service.dart';
import 'package:gruve_app/features/story_preview/data/datasource/post_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/app_navigator.dart';

/// Immutable UI state for the post-share flow (recipient picker + search).
@immutable
class PostShareState {
  const PostShareState({
    this.selectedUsers = const {},
    this.isSending = false,
    this.searchResults = const [],
    this.isSearching = false,
    this.searchError,
    this.searchQuery = '',
  });

  final Set<SearchUser> selectedUsers;
  final bool isSending;
  final List<SearchUser> searchResults;
  final bool isSearching;
  final String? searchError;
  final String searchQuery;

  PostShareState copyWith({
    Set<SearchUser>? selectedUsers,
    bool? isSending,
    List<SearchUser>? searchResults,
    bool? isSearching,
    String? searchError,
    bool clearSearchError = false,
    String? searchQuery,
  }) {
    return PostShareState(
      selectedUsers: selectedUsers ?? this.selectedUsers,
      isSending: isSending ?? this.isSending,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Replaces the previous `PostShareProvider` (ChangeNotifier). Owns
/// recipient selection, the debounced user search, and the share API call.
class PostShareNotifier extends Notifier<PostShareState> {
  late final PostService _postService;
  late final DebouncedUserSearch _userSearch;

  @override
  PostShareState build() {
    _postService = PostService();
    _userSearch = DebouncedUserSearch();
    ref.onDispose(_userSearch.dispose);
    return const PostShareState();
  }

  void toggleUser(SearchUser user) {
    if (state.isSending) return;

    final updated = {...state.selectedUsers};
    final exists = updated.any((u) => u.id == user.id);
    if (exists) {
      updated.removeWhere((u) => u.id == user.id);
    } else {
      updated.add(user);
    }
    state = state.copyWith(selectedUsers: updated);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, clearSearchError: true);

    if (query.trim().isEmpty) {
      _userSearch.clear();
      state = state.copyWith(searchResults: const [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true);

    _userSearch.search(
      query,
      onResults: (users) {
        state = state.copyWith(searchResults: users, isSearching: false);
      },
      onError: (error) {
        state = state.copyWith(
          searchResults: const [],
          isSearching: false,
          searchError: 'Unable to search users right now',
        );
      },
    );
  }

  void clearSelection() {
    _userSearch.clear();
    state = const PostShareState();
  }

  Future<bool> sharePost(String postId) async {
    if (state.selectedUsers.isEmpty || state.isSending) return false;

    state = state.copyWith(isSending: true);

    final recipientIds = state.selectedUsers.map((u) => u.id).toList();
    final names = state.selectedUsers.map((u) => u.username).join(', ');

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
      AppLogger.d('❌ [PostShareNotifier] Error sharing post: $e');
      state = state.copyWith(isSending: false);
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

final postShareNotifierProvider =
    NotifierProvider<PostShareNotifier, PostShareState>(PostShareNotifier.new);
