import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/constants/post/more_constants.dart';

class MoreToggle extends StatelessWidget {
  final String title;
  final String description;
  final String icon; // 👈 Add icon parameter
  final bool value;
  final ValueChanged<bool> onChanged;

  const MoreToggle({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), // Reduced spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 1. ICON
          Image.asset(icon, width: 24, height: 24, color: Colors.white),
          const SizedBox(width: 16),

          /// 2. TEXT AREA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MoreConstants.titleStyle),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: MoreConstants.descriptionStyle.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),

          /// 3. SWITCH
          Transform.scale(
            scale: 0.8, // Make switch look compact like SS
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white24, // Subtle track color
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}
