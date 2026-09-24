import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/auth/auth_state_manager.dart';
import 'package:gruve_app/core/pagination/pagination_scroll_trigger.dart';
import 'package:gruve_app/core/services/profile_identity_service.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/search/data/datasource/user_search_service.dart';
import 'package:gruve_app/features/search/presentation/widgets/search_bar.dart';
import 'package:gruve_app/features/story_preview/data/datasource/close_friend_service.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/close_friend/close_friend_header.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/close_friend/close_friend_user_list.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/hide_story_widgets/done_button.dart';

class CloseFriendScreen extends StatefulWidget {
  final Set<String> initialSelectedUserIds;

  const CloseFriendScreen({
    super.key,
    this.initialSelectedUserIds = const {},
  });

  @override
  State<CloseFriendScreen> createState() => _CloseFriendScreenState();
}

class _CloseFriendScreenState extends State<CloseFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CloseFriendService _service = CloseFriendService();
  final ScrollController _scrollController = ScrollController();
  final PaginationScrollTrigger _paginationTrigger = PaginationScrollTrigger();
  late final Set<String> _selectedUserIds;

  List<SearchUser> _allUsers = [];
  List<SearchUser> _visibleUsers = [];
  CancelToken? _cancelToken;
  int _nextPage = 1;
  bool _hasNext = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _selectedUserIds = {...widget.initialSelectedUserIds};
    _scrollController.addListener(_onScroll);
    _fetchConnections();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Screen disposed');
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _resolveCurrentUserId() {
    final authId = AuthStateManager().currentUserId?.trim();
    if (authId != null && authId.isNotEmpty) return authId;
    return ProfileIdentityService.instance.cachedLoggedInUserId?.trim();
  }

  Future<void> _fetchConnections({bool loadMore = false}) async {
    final userId = _resolveCurrentUserId();
    if (userId == null || userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load close friends right now';
      });
      return;
    }

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
      }
    });

    _cancelToken?.cancel('Superseded by a newer request');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    try {
      final result = await _service.fetchSubscribedConnections(
        userId: userId,
        page: loadMore ? _nextPage : 1,
        cancelToken: cancelToken,
      );

      if (!mounted) return;

      setState(() {
        _allUsers = loadMore ? [..._allUsers, ...result.users] : result.users;
        _hasNext = result.hasNext;
        _nextPage = result.page + 1;
        _selectedUserIds.addAll(
          result.users.where((u) => u.isCloseFriend).map((u) => u.id),
        );
        _applyFilter();
      });
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (!mounted) return;
      AppLogger.d('[CloseFriendScreen] fetch failed: $e');
      setState(() {
        _errorMessage = 'Unable to load close friends right now';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_paginationTrigger.shouldLoadMore(
      _scrollController,
      isLoading: _isLoadingMore,
      hasMore: _hasNext,
    )) {
      return;
    }
    _fetchConnections(loadMore: true);
  }

  void _onSearchChanged(String query) {
    setState(_applyFilter);
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    _visibleUsers = query.isEmpty
        ? _allUsers
        : _allUsers
              .where(
                (user) =>
                    user.name.toLowerCase().contains(query) ||
                    user.username.toLowerCase().contains(query),
              )
              .toList();
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

  Future<void> _handleDone() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await _service.updateCloseFriends(_selectedUserIds.toList());

      if (!mounted) return;

      final selectedUsers = _allUsers
          .where((user) => _selectedUserIds.contains(user.id))
          .toList();
      Navigator.pop(context, selectedUsers);
    } catch (e) {
      AppLogger.d('[CloseFriendScreen] updateCloseFriends failed: $e');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Unable to save close friends right now';
      });
    }
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

            SizedBox(height: context.rh(10)),

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
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white,
                size: context.rw(23),
              ),
              hintStyle: TextStyle(
                color: Colors.white,
                fontSize: context.rf(14),
              ),
              onChanged: _onSearchChanged,
            ),

            SizedBox(height: context.rh(20)),

            /// MULTI SELECT USER LIST
            Expanded(
              child: CloseFriendUserList(
                users: _visibleUsers,
                selectedUserIds: _selectedUserIds,
                isLoading: _isLoading,
                isLoadingMore: _isLoadingMore,
                errorMessage: _errorMessage,
                onToggle: _toggleUser,
                scrollController: _scrollController,
              ),
            ),

            if (_saveError != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rw(20)),
                child: Text(
                  _saveError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),

            /// DONE BUTTON
            Padding(
              padding: EdgeInsets.all(context.rw(20)),
              child: DoneButton(onDone: _handleDone, isLoading: _isSaving),
            ),
          ],
        ),
      ),
    );
  }
}
