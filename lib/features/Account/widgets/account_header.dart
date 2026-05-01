import 'package:flutter/material.dart';
import '../../../../core/assets.dart';

/// Header widget for Account screen
class AccountHeader extends StatelessWidget {
  final String fullName;
  final bool isLoading;

  const AccountHeader({
    super.key,
    this.fullName = 'User',
    this.isLoading = false,
  });

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
              top: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(30),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: SizedBox(
                    height: 60,
                    width: 50,
                    child: Center(
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Image.asset(AppAssets.back),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 25,
              left: 0,
              right: 0,
              child: Text(
                isLoading
                    ? 'Loading...'
                    : fullName.isEmpty
                        ? 'Hey, User'
                        : 'Hey, $fullName',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
