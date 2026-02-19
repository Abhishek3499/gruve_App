import 'package:flutter/material.dart';

class SubscribeButton extends StatelessWidget {
  const SubscribeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 2, right: 12),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🔥 Circle Left
          Container(
            width: 34,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD42BC2).withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 18, color: Color(0xFFD42BC2)),
          ),

          const SizedBox(width: 10),

          /// 🔥 Text
          const Text(
            "Subscribe",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
