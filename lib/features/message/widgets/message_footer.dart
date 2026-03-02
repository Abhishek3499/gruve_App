import 'package:flutter/material.dart';

class MessageFooter extends StatelessWidget {
  const MessageFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Text(
            'Made in India',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'Syncopate',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Powered by Hardkore Tech',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'Syncopate',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
