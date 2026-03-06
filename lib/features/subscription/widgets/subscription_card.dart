import 'package:flutter/material.dart';
import 'slanted_card_clipper.dart';

class SubscriptionCard extends StatelessWidget {
  final String iconPath;
  final int coins;
  final String? centerImage;
  final String price;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  const SubscriptionCard({
    super.key,
    required this.iconPath,
    required this.coins,
    this.centerImage,
    required this.price,
    this.isSelected = false,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ClipPath(
          clipper: SlantedCardClipper(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [const Color(0xFF4A2563), const Color(0xFF2A1A3A)]
                    : [const Color(0xFF3B1D52), const Color(0xFF1E122D)],
              ),
              border: isSelected
                  ? Border.all(color: const Color(0xFFB86AD0), width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFB86AD0).withValues(alpha: 0.6),
                        blurRadius: 25,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 50,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: AnimatedOpacity(
              opacity: isLocked
                  ? 0.4
                  : isSelected
                  ? 1.0
                  : 0.6,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// Left side
                        Row(
                          children: [
                            Image.asset(iconPath, height: 32),
                            const SizedBox(width: 15),
                            Text(
                              '$coins',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        /// Right side
                        Text(
                          price,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Center image
                  if (centerImage != null)
                    Image.asset(centerImage!, height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
