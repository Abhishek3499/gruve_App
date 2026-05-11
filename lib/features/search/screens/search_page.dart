import 'dart:async'; // Added for Timer debounce
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
  final DebouncedUserSearch _userSearch = DebouncedUserSearch(); // Changed delay to 400ms in service
  final RecentSearchService _recentSearchService = RecentSearchService();

  List<SearchHistoryModel> _searchHistory = [];
  List<SearchUser> _recentSearches = [];
  List<SearchUser> _users = [];
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounceTimer; // Added for custom debounce control

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
    _debounceTimer?.cancel(); // CHANGED: Cancel debounce timer on dispose
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
    // Cancel existing debounce timer
    _debounceTimer?.cancel();
    
    // CHANGED: Clear results immediately when user types, set searching state
    setState(() {
      _users = []; // Clear previous results instantly
      _searchError = null; // Clear any previous errors
      _isSearching = query.trim().isNotEmpty; // Only show loader when there's text
    });

    // CHANGED: Handle empty query case - clear debounced search
    if (query.trim().isEmpty) {
      _userSearch.clear();
      return;
    }

    // CHANGED: Add 400ms debounce using Timer instead of relying on service debounce
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return; // Safety check
      
      // Only proceed if still searching (user hasn't cleared the query)
      if (query.trim().isNotEmpty) {
        _userSearch.search(
          query,
          onResults: (users) {
            if (!mounted) return;
            setState(() {
              _users = users;
              _isSearching = false; // Stop loader when results arrive
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _users = [];
              _isSearching = false; // Stop loader on error
              _searchError = 'Unable to search users right now';
            });
          },
        );
      }
    });
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
    // CHANGED: Simplified state variables for clear if-else if logic
    final bool isEmptySearch = _searchController.text.isEmpty;
    final bool hasResults = _users.isNotEmpty;
    final bool isLoading = _isSearching;
    final bool hasError = _searchError != null;
    final bool hasRecentSearches = _recentSearches.isNotEmpty;
    final bool showEmptyState = isEmptySearch && !hasRecentSearches; // Only show empty when no searches and no recents

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
                    // CHANGED: Single if-else if chain - only ONE state shows at a time
                    
                    // STATE 1: Empty search with no recent searches - show empty hint
                    if (showEmptyState) ...[
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
                    ] 
                    // STATE 2: Empty search with recent searches - show recent searches only
                    else if (isEmptySearch && hasRecentSearches) ...[
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
                    ]
                    // STATE 3: Loading state - show shimmer only when user has typed and API is in progress
                    else if (isLoading) ...[
                      // CHANGED: Only show loader when user has typed something AND search is in progress
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: SearchResultsShimmer(itemCount: 6),
                      ),
                    ]
                    // STATE 4: Error state - show error message only when API has failed
                    else if (hasError) ...[
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
                    else if (!isEmptySearch && !isLoading && !hasError && !hasResults) ...[
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                color: Colors.white54,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try different keywords',
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
