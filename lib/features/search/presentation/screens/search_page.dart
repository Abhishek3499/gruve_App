import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/features/search/data/datasource/user_search_service.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/search/domain/entities/search_history_model.dart';
import 'package:gruve_app/features/search/domain/entities/search_navigation_type.dart';
import 'package:gruve_app/features/search/presentation/widgets/search_bar.dart';

import 'package:gruve_app/features/search/data/datasource/recent_search_service.dart';
import 'package:gruve_app/shared/widgets/shimmer/search_shimmer.dart';
import 'package:gruve_app/features/message/presentation/controller/message_provider.dart';
import 'package:gruve_app/features/message/presentation/screens/chat_screen.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/user_profile_screen.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

class SearchPage extends StatefulWidget {
  final SearchNavigationType navigationType;

  const SearchPage({
    super.key,
    this.navigationType = SearchNavigationType.profile,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  SearchNavigationType get _navigationType => widget.navigationType;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DebouncedUserSearch _userSearch =
      DebouncedUserSearch(); // Changed delay to 400ms in service
  final RecentSearchService _recentSearchService = RecentSearchService();

  List<SearchHistoryModel> _searchHistory = [];
  List<SearchUser> _recentSearches = [];
  List<SearchUser> _users = [];
  bool _isSearching = false;
  bool _isNavigating = false;
  bool _isClosing = false;
  bool _allowPop = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final recentSearches = await _recentSearchService.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = recentSearches;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _userSearch.dispose();
    super.dispose();
  }

  void _addToHistory(String query) {
    if (query.trim().isEmpty) return;

    final newHistoryItem = SearchHistoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      query: query.trim(),
      type: SearchType.user, // Default to user type
      subtitle: 'Recent search',
    );

    setState(() {
      _searchHistory.removeWhere(
        (item) => item.query.toLowerCase() == query.toLowerCase(),
      );

      _searchHistory.insert(0, newHistoryItem);

      if (_searchHistory.length > 20) {
        _searchHistory = _searchHistory.take(20).toList();
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    _addToHistory(query);
  }

  Future<void> _closeSearch() async {
    if (_isClosing) return;

    _isClosing = true;
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    if (mounted) {
      setState(() {
        _allowPop = true;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    Navigator.of(context).pop();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _users = [];
      _searchError = null;
      _isSearching = query.trim().isNotEmpty;
    });

    if (query.trim().isEmpty) {
      _userSearch.clear();
      return;
    }

    // Single debounce handled by DebouncedUserSearch (300ms)
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

  Future<void> _navigateToUserProfile(SearchUser user) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      await _recentSearchService.addRecentSearch(user);
      if (!mounted) return;

      if (_navigationType == SearchNavigationType.profile) {
        AppLogger.d(
          '👤 [SearchPage] Opening profile for user: ${user.username}',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(
              profileUserId: user.id,
              userName: user.name,
              profileImageUrl: user.avatar.isNotEmpty ? user.avatar : null,
            ),
          ),
        ).then((_) => _loadRecentSearches());
      } else {
        AppLogger.d(
          '💬 [SearchPage] Opening chat for user: ${user.username} (ID: ${user.id})',
        );

        final messageProvider = context.read<MessageProvider>();

        final existingConversation = messageProvider.getConversationByUserId(
          user.id,
        );

        if (existingConversation != null) {
          AppLogger.d(
            '✅ [SearchPage] Existing conversation found: ${existingConversation.id}',
          );
          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: existingConversation.id,
                receiverId: user.id,
                userName: user.name,
                profileImage: user.avatar.isNotEmpty ? user.avatar : null,
                userOrConversation: existingConversation,
              ),
            ),
          ).then((_) {
            _loadRecentSearches();
            if (mounted) {
              context.read<MessageProvider>().fetchConversations(refresh: true);
            }
          });
        } else {
          AppLogger.d(
            '🆕 [SearchPage] Opening ChatScreen immediately for user: ${user.name}',
          );
          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                receiverId: user.id,
                userName: user.name,
                profileImage: user.avatar.isNotEmpty ? user.avatar : null,
              ),
            ),
          ).then((_) {
            _loadRecentSearches();
            if (mounted) {
              context.read<MessageProvider>().fetchConversations(refresh: true);
            }
          });
        }
      }
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // CHANGED: Simplified state variables for clear if-else if logic
    final bool isEmptySearch = _searchController.text.isEmpty;
    final bool hasResults = _users.isNotEmpty;
    final bool isLoading = _isSearching;
    final bool hasError = _searchError != null;
    final bool hasRecentSearches = _recentSearches.isNotEmpty;
    final bool showEmptyState =
        isEmptySearch &&
        !hasRecentSearches; // Only show empty when no searches and no recents

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeSearch();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.2, -1.0),
              end: Alignment(0.2, 1.0),
              colors: [Color(0xFF42174C), Color(0xFF210C26), Color(0xFF000000)],
              stops: [0.0, 0.4172, 0.9933],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                /// HEADER
                Padding(
                  padding: EdgeInsets.all(context.rw(16)),
                  child: Row(
                    children: [
                      BackButton(
                        color: Colors.white,
                        onPressed: _closeSearch,
                      ),
                      SizedBox(width: context.rw(22)),

                      /// SEARCH BAR
                      Expanded(
                        child: CustomSearchBar(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          onSubmitted: _onSearchSubmitted,
                        ),
                      ),
                    ],
                  ),
                ),

                /// CONTENT
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(bottom: context.rh(34)),
                    children: [
                      // CHANGED: Single if-else if chain - only ONE state shows at a time

                      // STATE 1: Empty search with no recent searches - show empty hint
                      if (showEmptyState) ...[
                        Padding(
                          padding: EdgeInsets.all(context.rw(32)),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_outlined,
                                  color: Colors.white54,
                                  size: context.rw(48),
                                ),
                                SizedBox(height: context.rh(16)),
                                Text(
                                  'No recent searches',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: context.rf(16),
                                  ),
                                ),
                                SizedBox(height: context.rh(8)),
                                Text(
                                  'Start typing to see suggestions',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: context.rf(14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]
                      // STATE 2: Empty search with recent searches - show recent searches only
                      else if (isEmptySearch && hasRecentSearches) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.rw(16),
                            context.rh(8),
                            context.rw(16),
                            context.rh(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.rf(18),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _recentSearchService.clearAll();
                                  _loadRecentSearches();
                                },
                                child: Text(
                                  'Clear all',
                                  style: TextStyle(
                                    color: Color(0xFFD42BC2),
                                    fontSize: context.rf(14),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        ..._recentSearches.map(
                          (user) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white24,
                              backgroundImage: user.avatar.isNotEmpty
                                  ? NetworkImage(user.avatar)
                                  : AssetImage(AppAssets.profile)
                                        as ImageProvider,
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '@${user.username}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: GestureDetector(
                              onTap: () async {
                                await _recentSearchService.removeRecentSearch(
                                  user.id,
                                );
                                _loadRecentSearches();
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.white54,
                                size: context.rw(20),
                              ),
                            ),
                            onTap: () => _navigateToUserProfile(user),
                          ),
                        ),

                        SizedBox(height: context.rh(20)),
                      ]
                      // STATE 3: Loading state - show shimmer only when user has typed and API is in progress
                      else if (isLoading) ...[
                        // CHANGED: Only show loader when user has typed something AND search is in progress
                        Padding(
                          padding: EdgeInsets.only(top: context.rh(16)),
                          child: SearchResultsShimmer(itemCount: 6),
                        ),
                      ]
                      // STATE 4: Error state - show error message only when API has failed
                      else if (hasError) ...[
                        Padding(
                          padding: EdgeInsets.all(context.rw(24)),
                          child: Center(
                            child: Text(
                              _searchError!,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: context.rf(14),
                              ),
                            ),
                          ),
                        ),
                      ]
                      // STATE 5: Results state - show search results only when API has responded with data
                      else if (hasResults) ...[
                        ..._users.map(
                          (user) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white24,
                              backgroundImage: user.avatar.isNotEmpty
                                  ? NetworkImage(user.avatar)
                                  : AssetImage(AppAssets.profile)
                                        as ImageProvider,
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '@${user.username}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            onTap: () => _navigateToUserProfile(user),
                          ),
                        ),
                      ]
                      // STATE 6: No results found - when search completed but returned empty
                      else if (!isEmptySearch &&
                          !isLoading &&
                          !hasError &&
                          !hasResults) ...[
                        Padding(
                          padding: EdgeInsets.all(context.rw(24)),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  color: Colors.white54,
                                  size: context.rw(48),
                                ),
                                SizedBox(height: context.rh(16)),
                                Text(
                                  'No results found',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: context.rf(16),
                                  ),
                                ),
                                SizedBox(height: context.rh(8)),
                                Text(
                                  'Try different keywords',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: context.rf(14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
