import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_search/user_search_service.dart';
import 'package:gruve_app/features/search/widgets/search_bar.dart';
import 'package:gruve_app/features/story_preview/widgets/close_friend/close_friend_header.dart';
import 'package:gruve_app/features/story_preview/widgets/close_friend/close_friend_user_list.dart';
import 'package:gruve_app/features/story_preview/widgets/hide_story_widgets/done_button.dart';

class CloseFriendScreen extends StatefulWidget {
  const CloseFriendScreen({super.key});

  @override
  State<CloseFriendScreen> createState() => _CloseFriendScreenState();
}

class _CloseFriendScreenState extends State<CloseFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DebouncedUserSearch _userSearch = DebouncedUserSearch();
  final Set<String> _selectedUserIds = {};
  List<SearchUser> _users = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    _userSearch.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchError = null;
      _isSearching = query.trim().isNotEmpty;
      if (query.trim().isEmpty) {
        _users = [];
      }
    });

    if (query.trim().isEmpty) {
      _userSearch.clear();
      return;
    }

    _userSearch.search(
      query,
      onResults: (users) {
        if (!mounted) return;
        setState(() {
          _users = users;
          _isSearching = false;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _users = [];
          _isSearching = false;
          _searchError = 'Unable to search users right now';
        });
      },
    );
  }

  void _toggleUser(SearchUser user) {
    setState(() {
      if (_selectedUserIds.contains(user.id)) {
        _selectedUserIds.remove(user.id);
      } else {
        _selectedUserIds.add(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 74, 5, 90),
              Color.fromARGB(255, 25, 2, 31),
            ],
          ),
        ),

        child: Column(
          children: [
            /// HEADER
            CloseFriendHeader(
              onBack: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 10),

            CustomSearchBar(
              controller: _searchController,
              hintText: 'Search',
              width: 362,
              borderRadius: 25,
              borderWidth: 4,
              backgroundGradient: const LinearGradient(
                colors: [Color(0xFF72008D), Color(0xFF511263)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white,
                size: 23,
              ),
              hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: _onSearchChanged,
            ),

            const SizedBox(height: 20),

            /// MULTI SELECT USER LIST
            Expanded(
              child: CloseFriendUserList(
                users: _users,
                selectedUserIds: _selectedUserIds,
                isSearching: _isSearching,
                errorMessage: _searchError,
                hasQuery: _searchController.text.trim().isNotEmpty,
                onToggle: _toggleUser,
              ),
            ),

            /// DONE BUTTON
            Padding(
              padding: const EdgeInsets.all(20),
              child: DoneButton(
                onDone: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
