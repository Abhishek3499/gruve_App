import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/views_model.dart';

/// Views count section widget
class ViewsCountSection extends StatelessWidget {
  const ViewsCountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          ViewsModel.data.totalViews,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Views',
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
