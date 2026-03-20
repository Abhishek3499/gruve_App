import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/models/archive_model/archive_tab.dart';

class ArchiveSwitcherTab extends StatelessWidget {
  final ArchiveTab selectedTab;
  final Function(ArchiveTab) onTabChanged;

  const ArchiveSwitcherTab({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// ICON TABS
        Row(
          children: [
            _buildTab(Icons.access_time, ArchiveTab.archive),
            _buildTab(Icons.favorite_border, ArchiveTab.favorite),
          ],
        ),

        const SizedBox(height: 8),

        /// LINE
        Stack(
          children: [
            Container(height: 2, color: Colors.white),

            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: selectedTab == ArchiveTab.archive
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width / 2,
                height: 3,
                color: const Color(0xFFFF00FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTab(IconData icon, ArchiveTab tab) {
    final isSelected = selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tab),
        child: Center(
          child: Icon(
            icon,
            size: 24,
            color: isSelected ? const Color(0xFFFF00FF) : Colors.white70,
          ),
        ),
      ),
    );
  }
}
