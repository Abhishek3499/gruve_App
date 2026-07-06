import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class TermHeader extends StatelessWidget {
  const TermHeader({super.key});
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
            'Terms & Conditions',
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
