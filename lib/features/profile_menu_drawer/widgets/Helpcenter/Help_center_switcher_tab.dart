import 'package:flutter/material.dart';

class HelpCenterSwitcherTab extends StatefulWidget {
  const HelpCenterSwitcherTab({super.key});

  @override
  State<HelpCenterSwitcherTab> createState() => _HelpCenterSwitcherTabState();
}

class _HelpCenterSwitcherTabState extends State<HelpCenterSwitcherTab> {
  int selectedIndex = 1; // 0 = FAQ, 1 = Contact us

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// TABS
        Row(children: [_buildTab("FAQ", 0), _buildTab("Contact us", 1)]),

        const SizedBox(height: 8),

        /// LINE UNDER TABS
        Stack(
          children: [
            /// BASE LINE
            Container(height: 2, color: Colors.white),

            /// ACTIVE INDICATOR
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: selectedIndex == 0
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

  Widget _buildTab(String title, int index) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
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
