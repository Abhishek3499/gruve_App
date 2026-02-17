import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FilterTabs extends StatelessWidget {
  const FilterTabs({super.key});

  Widget buildTab(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7D63D1).withOpacity(0.5),
            const Color(0xFF212235).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [buildTab("All"), buildTab("Trending"), buildTab("Likes")],
    );
  }
}
