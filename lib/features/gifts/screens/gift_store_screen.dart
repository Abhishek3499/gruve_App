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
            colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔥 WHITE HANDLE
              const SizedBox(height: 12),
              Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              GiftHeader(stonesCount: _stonesCount),

              GiftCategoryTabs(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) =>
                    setState(() => _selectedCategory = category),
              ),

              FlashSaleSection(
                timeRemaining: const Duration(hours: 10, minutes: 24),
              ),

              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85, // Adjusted for better fit
                  ),
                  itemCount: _gifts.length,
                  itemBuilder: (context, index) {
                    return GiftItem(
                      imagePath: _gifts[index]['image'],
                      stonesCost: _gifts[index]['cost'],
                      onTap: () {},
                    );
                  },
                ),
              ),

              GiftSearchBar(controller: _searchController, onSearch: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
