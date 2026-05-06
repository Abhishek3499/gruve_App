import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/user_search/user_search_service.dart';
import 'package:gruve_app/core/assets.dart';
import '../models/search_history_model.dart';
import '../widgets/search_bar.dart';
import '../widgets/search_history_item.dart';
import '../data/services/recent_search_service.dart';
import '../../user_profile/presentation/screens/user_profile_screen.dart';
import '../../../../core/widgets/shimmer/search_shimmer.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DebouncedUserSearch _userSearch = DebouncedUserSearch();
  final RecentSearchService _recentSearchService = RecentSearchService();

  List<SearchHistoryModel> _searchHistory = [];
  List<SearchUser> _recentSearches = [];
  List<SearchUser> _users = [];
  bool _isSearching = false;
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

  void _removeFromHistory(String id) {
    setState(() {
      _searchHistory.removeWhere((item) => item.id == id);
    });
  }

  void _clearAllHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    _addToHistory(query);
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

  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
    _onSearchSubmitted(query);
  }

  Future<void> _navigateToUserProfile(SearchUser user) async {
    // Save user to recent searches
    await _recentSearchService.addRecentSearch(user);

    // Navigate immediately to profile screen using same screen as video overlay
    if (!mounted) return;
    
    debugPrint('🔍 [SearchPage] Navigating to profile for user: ${user.username} (ID: ${user.id})');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          profileUserId: user.id,
          userName: user.name,
          profileImageUrl: user.avatar.isNotEmpty ? user.avatar : null,
          initialHasActiveStory: user.isOnline, // Use isOnline as story indicator
        ),
      ),
    ).then((_) => _loadRecentSearches()); // refresh recent searches on back
  }

  @override
  Widget build(BuildContext context) {
    final bool showEmptyState =
        _recentSearches.isEmpty && _searchHistory.isEmpty && _searchController.text.isEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF42174C), Color(0xFF9544A7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(AppAssets.back, height: 24, width: 24),
                    ),
                    const SizedBox(width: 22),

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
                  children: [
                    /// RECENT SEARCHES (shown when search field is empty)
                    if (_searchController.text.isEmpty && _recentSearches.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _recentSearchService.clearAll();
                                _loadRecentSearches();
                              },
                              child: const Text(
                                'Clear all',
                                style: TextStyle(
                                  color: Color(0xFFD42BC2),
                                  fontSize: 14,
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
                              await _recentSearchService.removeRecentSearch(user.id);
                              _loadRecentSearches();
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                          onTap: () => _navigateToUserProfile(user),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],

                    /// SEARCH HISTORY (legacy - shown when search has text)
                    if (_searchHistory.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Search',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: _clearAllHistory,
                              child: const Text(
                                'Clear all',
                                style: TextStyle(
                                  color: Color(0xFFD42BC2),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      ..._searchHistory.map(
                        (historyItem) => SearchHistoryItem(
                          historyItem: historyItem,
                          onTap: () => _onHistoryItemTap(historyItem.query),
                          onRemove: () => _removeFromHistory(historyItem.id),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],

                    if (_isSearching)
                      // ✅ SHIMMER while searching — shows user row shapes
                      // Prevents the jarring spinner → list jump
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: SearchResultsShimmer(itemCount: 6),
                      ),

                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            _searchError!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                    if (_users.isNotEmpty)
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

                    /// EMPTY STATE
                    if (showEmptyState)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_outlined,
                                color: Colors.white54,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No recent searches',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start typing to see suggestions',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
