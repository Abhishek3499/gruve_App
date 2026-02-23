import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/interactions_model.dart';

/// Interactions count section widget
class InteractionsCountSection extends StatelessWidget {
  const InteractionsCountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          InteractionsModel.data.totalInteractions,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Interactions',
          style: const TextStyle(
            color: AppColors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
