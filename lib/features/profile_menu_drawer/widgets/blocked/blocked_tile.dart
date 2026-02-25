import 'package:flutter/material.dart';

class BlockedUserTile extends StatelessWidget {
  final String image;
  final String name;
  final String username;
  final VoidCallback onUnblock;

  const BlockedUserTile({
    super.key,
    required this.image,
    required this.name,
    required this.username,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundImage: AssetImage(image)),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: const TextStyle(
                    color: Color(0xFFD0B5DA),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: onUnblock,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF72008D)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB44DFF).withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8), // 👈 niche se lift
                  ),
                ],
              ),
              child: const Text(
                "Unblock",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
