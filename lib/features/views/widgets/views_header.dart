import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Views header widget
class ViewsHeader extends StatelessWidget {
  const ViewsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.white.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.white,
                ),
              ),
            ),
          ),

          // Title
          const Text(
            "Views",
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
