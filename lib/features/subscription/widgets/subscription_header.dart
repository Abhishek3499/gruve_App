import 'package:flutter/material.dart';
import 'package:gruve_app/core/app_colors.dart';
import 'package:gruve_app/core/assets.dart';

class SubscriptionHeader extends StatelessWidget {
  const SubscriptionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        children: [
          /// 🔵 Background Image
          Positioned.fill(
            child: Image.asset(AppAssets.subscriptionbg, fit: BoxFit.cover),
          ),

          /// 🔙 Back Button
          Positioned(
            top: 35,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset(
                AppAssets.back,
                color: AppColors.white,
                width: 25,
                height: 25,
              ),
            ),
          ),

          /// ⭐ Center Icon + Text (Manually Adjusted)
          Positioned(
            top: 70, // 👈 isko adjust karo 80–110 ke beech
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    /// White Ribbon Image
                    Image.asset(
                      AppAssets.outline, // 👈 tera ribbon image
                      height: 50,
                    ),

                    /// Star Image
                    Image.asset(
                      AppAssets.star, // 👈 tera star image
                      height: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Buy Stones",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
