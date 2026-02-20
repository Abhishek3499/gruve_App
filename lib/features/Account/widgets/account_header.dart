import 'package:flutter/material.dart';
import '../../../../core/assets.dart';

/// Header widget for Account screen
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF42174C), Color(0xFF7A2C8F)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 15,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(AppAssets.back),
                ),
              ),
            ),

            const Positioned(
              top: 25,
              left: 0,
              right: 0,
              child: Text(
                "Hey, Kato",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
