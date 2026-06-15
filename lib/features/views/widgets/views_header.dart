import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

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
              onTap: () {
                AppLogger.d("[ViewsHeader] Back button tapped");
                Navigator.pop(context);
              },
              child: Image.asset(
                AppAssets.back,
                color: AppColors.white,
                width: 25,
                height: 25,
              ),
            ),
          ),

          // Title
          const Text(
            "Views",
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
