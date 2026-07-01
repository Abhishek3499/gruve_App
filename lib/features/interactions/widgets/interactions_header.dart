import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Interactions header widget
class InteractionsHeader extends StatelessWidget {
  const InteractionsHeader({super.key});

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
            child: BackButton(
              color: AppColors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Title
          const Text(
            "Interactions",
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'syncopate',
            ),
          ),
        ],
      ),
    );
  }
}
