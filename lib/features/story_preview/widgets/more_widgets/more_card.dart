import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/constants/post/more_constants.dart';

class MoreCard extends StatelessWidget {
  final Widget child;

  const MoreCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: MoreConstants.cardGradient,
        borderRadius: BorderRadius.circular(MoreConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: MoreConstants.shadowColor.withValues(alpha: 0.6), // 👈 fix
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
