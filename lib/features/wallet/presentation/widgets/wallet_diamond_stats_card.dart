import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class WalletDiamondStatsCard extends StatelessWidget {
  const WalletDiamondStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Month Dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "September 2020",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
          ],
        ),

        const SizedBox(height: 25),

        /// Diamond + Number
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.walletdiamond, width: 40, height: 40),
            const SizedBox(width: 15),

            Text(
              "1,812",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xB2FF00FF), // must be white for ShaderMask
              ),
            ),
          ],
        ),
      ],
    );
  }
}
