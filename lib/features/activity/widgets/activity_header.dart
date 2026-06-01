import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class ActivityHeader extends StatelessWidget {
  final VoidCallback onBackPressed;

  const ActivityHeader({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBackPressed,
              child: Image.asset(AppAssets.back, width: 25, height: 25),
            ),
          ),
          const Text(
            "ACTIVITY",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'syncopate',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
