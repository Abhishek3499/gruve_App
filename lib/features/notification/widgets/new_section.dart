import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

import 'notification_tile.dart';

class NewSection extends StatelessWidget {
  const NewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 01),
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF833FB0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(70), // 🔥 curve yaha
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "New",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 15),

          NotificationTile(
            username: "karennne",
            message: "liked your video.",
            time: "1h",
            profileImage: AppAssets.newprofile,
          ),
        ],
      ),
    );
  }
}
