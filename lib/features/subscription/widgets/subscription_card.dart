import 'package:flutter/material.dart';
import 'slanted_card_clipper.dart';

class SubscriptionCard extends StatelessWidget {
  final String iconPath;
  final int coins;
  final String price;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  const SubscriptionCard({
    super.key,
    required this.iconPath,
    required this.coins,
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B1D52), Color(0xFF1E122D)],
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Padding(
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  /// Right side
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
