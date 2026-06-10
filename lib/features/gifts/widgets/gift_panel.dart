import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gift_header.dart';
import 'gift_category_tabs.dart';
import 'flash_sale_section.dart';
import 'gift_item.dart';
import 'gift_search_bar.dart';
import '../../../../core/assets.dart';

class GiftPanel extends StatefulWidget {
  const GiftPanel({super.key});

  @override
  State<GiftPanel> createState() => _GiftPanelState();
}

class _GiftPanelState extends State<GiftPanel> {
  GiftCategory _selectedCategory = GiftCategory.new_;
  final int _stonesCount = 0;
  final TextEditingController _searchController = TextEditingController();

  // Gift data with specific AppAssets icons and stone costs
  final List<Map<String, dynamic>> _gifts = [
    {'image': AppAssets.flower, 'cost': 5, 'isSpecial': false},
    {'image': AppAssets.heart2, 'cost': 6, 'isSpecial': false},
    {'image': AppAssets.flower, 'cost': 7, 'isSpecial': false},
    {'image': AppAssets.boost, 'cost': 3, 'isSpecial': false},
    {'image': AppAssets.gost2, 'cost': 9, 'isSpecial': false},
    {'image': AppAssets.heart2, 'cost': 4, 'isSpecial': false},
    {'image': AppAssets.flower, 'cost': 6, 'isSpecial': false},
    {'image': AppAssets.gost2, 'cost': 8, 'isSpecial': false},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(GiftCategory category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
    });
  }

  void _showGiftSnackBar(String message, BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100, // Position above the panel
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (overlayEntry != null) {
                      overlayEntry.remove();
                    }
                  },
                  child: const Icon(Icons.close, color: Colors.black, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(overlayEntry);

    // Auto-remove after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry != null) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(40), // Increased curve for more rounded look
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar for smooth drag indication
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 65,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          GiftHeader(stonesCount: _stonesCount),

          // Category tabs
          GiftCategoryTabs(
            selectedCategory: _selectedCategory,
            onCategorySelected: _onCategorySelected,
          ),

          // Flash sale section
          FlashSaleSection(
            timeRemaining: const Duration(
              hours: 10,
              minutes: 24,
              seconds: 0,
            ),
          ),

          // Gift grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.70, // 👈 alignment fix
                  ),
              itemCount: _gifts.length,
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                return GiftItem(
                  imagePath: gift['image'],
                  stonesCost: gift['cost'],
                  onTap: () {
                    // Add haptic feedback
                    HapticFeedback.lightImpact();

                    // Handle gift selection with custom overlay
                    _showGiftSnackBar(
                      'Selected ${gift['cost']} stones gift',
                      context,
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
              HapticFeedback.lightImpact();
              _showGiftSnackBar(
                'Search functionality coming soon!',
                context,
              );
            },
          ),
        ],
      ),
    );
  }
}
