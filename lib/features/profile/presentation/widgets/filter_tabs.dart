import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class FilterTabs extends StatelessWidget {
  const FilterTabs({super.key});

  Widget buildTab(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.profileGradientTop.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildTab("All"),
        buildTab("Trending"),
        buildTab("Likes"),
      ],
    );
  }
}
