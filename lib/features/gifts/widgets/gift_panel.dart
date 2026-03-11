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

class _GiftPanelState extends State<GiftPanel> with TickerProviderStateMixin {
  GiftCategory _selectedCategory = GiftCategory.new_;
  int _stonesCount = 0;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

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
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onCategorySelected(GiftCategory category) {
    setState(() {
      _selectedCategory = category;
    });

    // Add a subtle scale animation when category changes
    _fadeController.reset();
    _fadeController.forward();
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
              color: const Color(0xFFCD72E3),
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
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
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
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
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
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with staggered animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: Opacity(
                          opacity: value,
                          child: GiftHeader(stonesCount: _stonesCount),
                        ),
                      );
                    },
                  ),

                  // Category tabs with staggered animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: Opacity(
                          opacity: value,
                          child: GiftCategoryTabs(
                            selectedCategory: _selectedCategory,
                            onCategorySelected: _onCategorySelected,
                          ),
                        ),
                      );
                    },
                  ),

                  // Flash sale section with staggered animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: Opacity(
                          opacity: value,
                          child: FlashSaleSection(
                            timeRemaining: const Duration(
                              hours: 10,
                              minutes: 24,
                              seconds: 0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Gift grid with staggered animation
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 900),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: Opacity(
                            opacity: value,
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: _gifts.length,
                              itemBuilder: (context, index) {
                                final gift = _gifts[index];
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(
                                    milliseconds: 300 + (index * 50),
                                  ),
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 0.8 + (value * 0.2),
                                      child: Opacity(
                                        opacity: value,
                                        child: GiftItem(
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
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Search bar with staggered animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: Opacity(
                          opacity: value,
                          child: GiftSearchBar(
                            controller: _searchController,
                            onSearch: () {
                              HapticFeedback.lightImpact();
                              _showGiftSnackBar(
                                'Search functionality coming soon!',
                                context,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
