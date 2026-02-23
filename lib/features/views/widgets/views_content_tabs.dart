import 'package:flutter/material.dart';

import '../controllers/views_controller.dart';

/// Content type tabs widget
class ViewsContentTabs extends StatelessWidget {
  final ViewsController controller;

  const ViewsContentTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
          controller.tabs.length,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 24),
            child: _buildTab(controller.tabs[index], index),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isActive = controller.isTabActive(index);

    return GestureDetector(
      onTap: () => controller.selectTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// TEXT (ALWAYS WHITE)
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white, // 🔥 always white
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          /// SMALL PINK UNDERLINE (ONLY ACTIVE)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 2,
            width: isActive ? 40 : 0, // 🔥 small width
            decoration: const BoxDecoration(color: Color(0xFFFF3AFF)),
          ),
        ],
      ),
    );
  }
}
