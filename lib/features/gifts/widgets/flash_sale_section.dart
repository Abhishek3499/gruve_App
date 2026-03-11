import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class FlashSaleSection extends StatelessWidget {
  final Duration timeRemaining;

  const FlashSaleSection({super.key, required this.timeRemaining});

  @override
  Widget build(BuildContext context) {
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;
    final seconds = timeRemaining.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Lightning icon
          Image.asset(AppAssets.flash, height: 22, width: 20),

          const SizedBox(width: 12),

          // Flash sale text
          const Text(
            'Flash Sale Is On',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${hours.toString().padLeft(2, '0')}h:${minutes.toString().padLeft(2, '0')}m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
