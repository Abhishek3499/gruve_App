import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

import '../widgets/notification_tile.dart';

class TodaySection extends StatelessWidget {
  const TodaySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 24, 42),
      decoration: const BoxDecoration(
        color: Color(0xFF33123B),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(88)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Today",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
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
