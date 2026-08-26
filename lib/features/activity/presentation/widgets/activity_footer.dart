import 'package:flutter/material.dart';

class ActivityFooter extends StatelessWidget {
  const ActivityFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Text(
            'Make in India',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Powered by Hardcore Tech',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
    );
  }
}
