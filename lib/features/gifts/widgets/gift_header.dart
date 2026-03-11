import 'package:flutter/material.dart';
import '../../../../core/assets.dart';

class GiftHeader extends StatelessWidget {
  final int stonesCount;

  const GiftHeader({super.key, required this.stonesCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Gift icon + Supporters texts
          Row(
            children: [
              Image.asset(AppAssets.trophy, width: 20, height: 20),
              const SizedBox(width: 8),
              const Text(
                'Supporters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(width: 18),

          // Stones counter
          Row(
            children: [
              Image.asset(AppAssets.stone, width: 20, height: 20),
              const SizedBox(width: 6),
              Text(
                '$stonesCount Stones',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(width: 23),

          // Recharge button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB66BE3), Color(0xFF9C5BD6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green Circle with Plus
                Container(
                  width: 20,
                  height: 20,

                  child: Center(
                    child: Image.asset(AppAssets.plus, width: 30, height: 30),
                  ),
                ),

                const SizedBox(width: 6),

                const Text(
                  'Recharge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
