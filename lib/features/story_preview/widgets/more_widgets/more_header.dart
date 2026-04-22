import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class MoreHeader extends StatelessWidget {
  final VoidCallback onBack;

  const MoreHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 56, // Standard AppBar height
        width: double.infinity,
        child: Stack(
          children: [
            // 1. Title - Wrapped in Center to stay perfectly in the middle
            const Center(
              child: Text(
                "More Option",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // 2. Back Button - Wrapped in Positioned to stay on the left
            Positioned(
              left: 12, // Gap from the screen edge
              top: 0,
              bottom: 0,
              child: Center(
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.05,
                      ), // Optional: slight circle bg
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        AppAssets.back,
                        width: 24,
                        color: Colors
                            .white, // Forces the asset to be white if it's not
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
