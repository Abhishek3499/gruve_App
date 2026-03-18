import 'package:flutter/material.dart';

import '../widgets/share_user_grid.dart';
import '../widgets/share_social_buttons.dart';

class ShareBottomSheet extends StatelessWidget {
  const ShareBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCD72E3), Color(0xFF3C034A)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 65,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Title

          // User grid with search
          Expanded(flex: 3, child: ShareUserGrid()),

          // Social share buttons
          const ShareSocialButtons(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
