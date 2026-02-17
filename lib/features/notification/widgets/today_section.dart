import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

import '../widgets/notification_tile.dart';

class TodaySection extends StatelessWidget {
  const TodaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 02),
      padding: const EdgeInsets.symmetric(vertical: 45),
      decoration: const BoxDecoration(
        color: Color(0xFF33123B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(100), // 🔥 curve yaha
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "Today",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 15),

          NotificationTile(
            username: "kiero_d",
            message: "liked your video.",
            time: "3h",
            profileImage: AppAssets.nprofile,
            postImage: AppAssets.today,
          ),
          NotificationTile(
            username: "kiero_d",
            message: "liked your video.",
            time: "3h",
            profileImage: AppAssets.nprofile,
            postImage: AppAssets.today,
          ),
        ],
      ),
    );
  }
}
