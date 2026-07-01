import 'package:flutter/material.dart';

class ActivityHeader extends StatelessWidget {
  final VoidCallback onBackPressed;

  const ActivityHeader({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BackButton(
              color: Colors.white,
              onPressed: onBackPressed,
            ),
          ),
          const Text(
            "ACTIVITY",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'syncopate',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
