import 'package:flutter/material.dart';
import '../widgets/gift_header.dart';
import '../widgets/gift_category_tabs.dart';
import '../widgets/flash_sale_section.dart';
import '../widgets/gift_item.dart';
import '../widgets/gift_search_bar.dart';

class GiftStoreScreen extends StatefulWidget {
  const GiftStoreScreen({super.key});

  @override
  State<GiftStoreScreen> createState() => _GiftStoreScreenState();
}

class _GiftStoreScreenState extends State<GiftStoreScreen> {
  GiftCategory _selectedCategory = GiftCategory.new_;
  int _stonesCount = 0;
  final TextEditingController _searchController = TextEditingController();

  // Dummy gift data
  final List<Map<String, dynamic>> _gifts = [
    {'image': 'assets/images/heart_gift.png', 'cost': 5},
    {'image': 'assets/images/flower_gift.png', 'cost': 6},
    {'image': 'assets/images/moon_gift.png', 'cost': 7},
    {'image': 'assets/images/skull_gift.png', 'cost': 3},
    {'image': 'assets/images/heart_gift.png', 'cost': 9},
    {'image': 'assets/images/flower_gift.png', 'cost': 4},
    {'image': 'assets/images/moon_gift.png', 'cost': 6},
    {'image': 'assets/images/skull_gift.png', 'cost': 8},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFCD72E3), // 0%
              Color(0xFF3C034A), // 100%
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              GiftHeader(stonesCount: _stonesCount),

              // Category tabs
              GiftCategoryTabs(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),

              // Flash sale section
              FlashSaleSection(
                timeRemaining: const Duration(hours: 10, minutes: 24),
              ),

              // Gift grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _gifts.length,
                  itemBuilder: (context, index) {
                    final gift = _gifts[index];
                    return GiftItem(
                      imagePath: gift['image'],
                      stonesCost: gift['cost'],
                      onTap: () {
                        // Handle gift selection
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Selected ${gift['cost']} stones gift',
                            ),
                            backgroundColor: const Color(0xFFCD72E3),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Search bar
              GiftSearchBar(
                controller: _searchController,
                onSearch: () {
                  // Handle search
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Search functionality coming soon!'),
                      backgroundColor: Color(0xFFCD72E3),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
