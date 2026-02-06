import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'nav_item.dart';
import 'center_nav_button.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          /// MAIN BAR
          Container(
            margin: EdgeInsets.zero,

            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF42174C),
                  Color(0xFF210C26),
                  Color(0xFF000000),
                ],
              ),
              border: Border.all(width: 1, color: const Color(0xFFFF3AFF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavItem(
                  imagePath: AppAssets.homelogo,
                  index: 0,
                  selectedIndex: widget.selectedIndex,
                  onTap: () => widget.onItemSelected(0),
                ),
                NavItem(
                  imagePath: AppAssets.search,
                  index: 1,
                  selectedIndex: widget.selectedIndex,
                  onTap: () => widget.onItemSelected(1),
                ),

                const SizedBox(width: 56), // center space

                NavItem(
                  imagePath: AppAssets.notification, // 🔥 PNG IMAGE
                  index: 3,
                  selectedIndex: widget.selectedIndex,
                  onTap: () => widget.onItemSelected(3),
                ),
                NavItem(
                  imagePath: AppAssets.user,
                  index: 4,
                  selectedIndex: widget.selectedIndex,
                  onTap: () => widget.onItemSelected(4),
                ),
              ],
            ),
          ),

          /// CENTER FLOATING +
          Positioned(
            top: 10,
            child: CenterNavButton(
              isSelected: widget.selectedIndex == 2,
              onTap: () => widget.onItemSelected(2),
            ),
          ),
        ],
      ),
    );
  }
}
