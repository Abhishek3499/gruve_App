import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            SizedBox(width: 16),
            Icon(Icons.arrow_back_ios, color: Colors.white),
            Spacer(),
            Text(
              "NOTIFICATIONS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            SizedBox(width: 16),
          ],
        ),
        SizedBox(height: 20),

        /// Tabs
        Row(
          children: const [
            SizedBox(width: 20),
            Text("All", style: TextStyle(color: Colors.white)),
            SizedBox(width: 20),
            Text("Unread", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}
