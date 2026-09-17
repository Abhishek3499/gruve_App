import 'package:flutter/material.dart';

/// Custom list tile for Insight screen
class InsightListTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const InsightListTile({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
              ],
            ),
          ),
        ),
        const Divider(
          height: 1,
          color: Colors.white24,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }
}
