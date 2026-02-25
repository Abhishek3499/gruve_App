import 'package:flutter/material.dart';
import '../constants/privacy_constants.dart';

class PrivacyCard extends StatelessWidget {
  final Widget child;

  const PrivacyCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: PrivacyConstants.cardGradient,
        borderRadius: BorderRadius.circular(PrivacyConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: PrivacyConstants.shadowColor.withOpacity(0.6),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: child,
    );
  }
}
