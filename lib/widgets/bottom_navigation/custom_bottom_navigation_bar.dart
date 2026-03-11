import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'nav_item.dart';
import 'nav_bar_clipper.dart';
import 'center_nav_button.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // NAVBAR with CustomPaint
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: NavBarPainter(),
              child: SizedBox(
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 28,
                  ), // icons neeche push karo
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      NavItem(
                        imagePath: AppAssets.homelogo,
                        index: 0,
                        selectedIndex: selectedIndex,
                        onTap: () => onItemSelected(0),
                      ),
                      NavItem(
                        imagePath: AppAssets.search,
                        index: 1,
                        selectedIndex: selectedIndex,
                        onTap: () => onItemSelected(1),
                      ),
                      const SizedBox(width: 55),
                      NavItem(
                        imagePath: AppAssets.notification,
                        index: 3,
                        selectedIndex: selectedIndex,
                        onTap: () => onItemSelected(3),
                      ),
                      NavItem(
                        imagePath: AppAssets.user,
                        index: 4,
                        selectedIndex: selectedIndex,
                        onTap: () => onItemSelected(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CENTER BUTTON
          Positioned(
            top: 35,
            child: CenterNavButton(
              isSelected: selectedIndex == 2,
              onTap: () => onItemSelected(2),
            ),
          ),
        ],
      ),
    );
  }
}
