import 'package:flutter/material.dart';
import '../../../../core/assets.dart';

class GiftItem extends StatelessWidget {
  final String imagePath;
  final int stonesCost;
  final VoidCallback onTap;
  final bool isSpecial;
  final String? specialText;

  const GiftItem({
    super.key,
    required this.imagePath,
    required this.stonesCost,
    required this.onTap,
    this.isSpecial = false,
    this.specialText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          /// Gift circle
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: isSpecial
                    ? Colors.blue
                    : Colors.white.withValues(alpha: 0.2),
                width: isSpecial ? 2 : 1,
              ),
            ),
            child: Center(
              child: Image.asset(
                imagePath,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 8),

          /// 🔥 FIXED ALIGN TEXT (MAIN FIX)
          SizedBox(
            width: 80, // 👈 sabka same width
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AppAssets.stone, width: 16, height: 16),
                const SizedBox(width: 4),

                Flexible(
                  child: Text(
                    isSpecial && specialText != null
                        ? specialText!
                        : '$stonesCost Stones',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSpecial ? Colors.blue : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Special badge
          if (isSpecial && specialText != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                specialText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
