import 'package:flutter/material.dart';
import '../../../../core/assets.dart';

class GiftHeader extends StatelessWidget {
  final int stonesCount;
  const GiftHeader({super.key, required this.stonesCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 🔥 Spread content
        children: [
          Row(
            children: [
              Image.asset(AppAssets.trophy, width: 18, height: 18),
              const SizedBox(width: 6),
              const Text(
                'Supporters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Image.asset(AppAssets.stone, width: 18, height: 18),
              const SizedBox(width: 4),
              Text(
                '$stonesCount Stones',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Recharge Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB66BE3), Color(0xFF9C5BD6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Image.asset(AppAssets.plus, width: 14, height: 14),
                const SizedBox(width: 6),
                const Text(
                  'Recharge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
