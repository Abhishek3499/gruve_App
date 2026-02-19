import 'package:flutter/material.dart';

class UserFilterTabs extends StatefulWidget {
  const UserFilterTabs({super.key});

  @override
  State<UserFilterTabs> createState() => _UserFilterTabsState();
}

class _UserFilterTabsState extends State<UserFilterTabs> {
  int selectedIndex = 0;

  Widget buildTab(String text, int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 08),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),

          // ✅ Center Fill
          color: isSelected
              ? const Color(0xFFFF3AFF) // pink fill
              : null,

          // ✅ Gradient for unselected
          gradient: isSelected
              ? null
              : LinearGradient(
                  colors: [
                    const Color(0xFF7D63D1).withValues(alpha: 0.5),
                    const Color(0xFF212235).withValues(alpha: 0.6),
                  ],
                ),

          // ✅ Border
          border: Border.all(
            color: isSelected ? const Color(0xFFFF3AFF) : Colors.transparent,
            width: 2,
          ),

          // ✅ Glow effect
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Color(0x66FF3AFF),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildTab("Gruves", 0),
        const SizedBox(width: 20),
        buildTab("Likes", 1),
      ],
    );
  }
}
