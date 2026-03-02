import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 16),

            /// BACK BUTTON
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            const Spacer(),

            /// TITLE
            const Text(
              "NOTIFICATIONS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            const SizedBox(width: 48), // equal spacing for balance
          ],
        ),

        const SizedBox(height: 20),

        /// TABS
        Row(
          children: const [
            SizedBox(width: 20),
            Text(
              "All",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 20),
            Text("Unread", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}
