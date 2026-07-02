import 'package:flutter/material.dart';
import 'package:gruve_app/features/search/controllers/explore_reels_controller.dart';
import 'package:gruve_app/features/search/widgets/explore_reels_grid.dart';
import 'package:gruve_app/features/search/widgets/search_bar.dart';

import 'search_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ExploreReelsController _exploreController;

  @override
  void initState() {
    super.initState();
    _exploreController = ExploreReelsController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _exploreController.loadInitial();
    });
  }

  @override
  void dispose() {
    _exploreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomSearchBar(
                  readOnly: true,
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ExploreReelsGrid(controller: _exploreController),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
