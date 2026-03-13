import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import '../models/search_history_model.dart';
import '../widgets/search_bar.dart';
import '../widgets/search_history_item.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<SearchHistoryModel> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _onSearchSubmitted(query);
  }

  @override
  Widget build(BuildContext context) {
    final bool showEmptyState =
        _searchHistory.isEmpty && _searchController.text.isEmpty;

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
                        onChanged: (value) {
                          setState(() {});
                        },
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
                    /// SEARCH HISTORY
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
