import 'package:flutter/material.dart';

/// Footer widget for Account screen
class AccountFooter extends StatelessWidget {
  const AccountFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splash_screen_logo/image 43.png',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 3),
            const Text(
              'Made in India',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'Syncopate',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Powered by  ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'Syncopate',
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'Hardkore Tech',
                style: TextStyle(
                  color: Color(0xFF72008D),
                  fontSize: 11,
                  fontFamily: 'Syncopate',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
