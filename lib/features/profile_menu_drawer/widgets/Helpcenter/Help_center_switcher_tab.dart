import 'package:flutter/material.dart';
import '../../models/help_center_tab.dart';

class HelpCenterSwitcherTab extends StatelessWidget {
  final HelpCenterTab selectedTab;
  final Function(HelpCenterTab) onTabChanged;

  const HelpCenterSwitcherTab({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// TABS
        Row(
          children: [
            _buildTab("FAQ", HelpCenterTab.faq),
            _buildTab("Contact us", HelpCenterTab.contact),
          ],
        ),

        const SizedBox(height: 8),

        /// LINE UNDER TABS
        Stack(
          children: [
            /// BASE LINE
            Container(height: 2, color: Colors.white),

            /// ACTIVE INDICATOR
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: selectedTab == HelpCenterTab.faq
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width / 2,
                height: 3,
                color: const Color(0xFFFF00FF), // pink line
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTab(String title, HelpCenterTab tab) {
    final isSelected = selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tab),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF00FF) : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
