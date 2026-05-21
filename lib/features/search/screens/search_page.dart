import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/api_calls/user_search/user_search_service.dart';
import 'package:gruve_app/core/assets.dart';
import '../models/search_history_model.dart';
import '../models/search_navigation_type.dart';
import '../widgets/search_bar.dart';

import '../data/services/recent_search_service.dart';
import '../../../../core/widgets/shimmer/search_shimmer.dart';
import '../../message/controllers/conversation_controller.dart';
import '../../message/providers/message_provider.dart';
import '../../message/screen/chat_screen.dart';
import '../../user_profile/presentation/screens/user_profile_screen.dart';

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
        debugPrint(
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
        debugPrint(
          '💬 [SearchPage] Opening chat for user: ${user.username} (ID: ${user.id})',
        );

        final messageProvider = context.read<MessageProvider>();
        final conversationController = context.read<ConversationController>();

        final existingConversation = messageProvider.getConversationByUserId(
          user.id,
        );

        if (existingConversation != null) {
          debugPrint(
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
          ).then((_) => _loadRecentSearches());
        } else {
          debugPrint(
            '🆕 [SearchPage] Creating new conversation with user: ${user.name}',
          );
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );

          try {
            final conversation = await conversationController
                .createOrGetConversation(user.id);

            final existingInProvider = messageProvider.getConversationById(
              conversation.id,
            );
            if (existingInProvider == null) {
              messageProvider.addConversation(conversation);
            }

            if (!mounted) return;
            Navigator.pop(context);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: conversation.id,
                  receiverId: user.id,
                  userName: user.name,
                  profileImage: user.avatar.isNotEmpty ? user.avatar : null,
                  userOrConversation: conversation,
                ),
              ),
            ).then((_) => _loadRecentSearches());
          } catch (e) {
            debugPrint('❌ [SearchPage] Error creating conversation: $e');
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start conversation: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
                              await _recentSearchService.removeRecentSearch(
                                user.id,
                              );
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
                    else if (!isEmptySearch &&
                        !isLoading &&
                        !hasError &&
                        !hasResults) ...[
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
