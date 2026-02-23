import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Views footer widget
class ViewsFooter extends StatelessWidget {
  const ViewsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),

        // Made in India
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splash_screen_logo/image 43.png',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 3),
            const Text(
              'Made in India',
              style: TextStyle(
                color: AppColors.white70,
                fontSize: 11,
                fontFamily: 'Syncopate',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Powered by
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Powered by  ',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontFamily: 'Syncopate',
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'Hardkore Tech',
                style: TextStyle(
                  color: Color(0xFF72008D),
                  fontSize: 11,
                  fontFamily: 'Syncopate',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
