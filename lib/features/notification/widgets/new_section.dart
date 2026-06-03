import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

import 'notification_tile.dart';

class NewSection extends StatelessWidget {
  const NewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 24, 38),
      decoration: const BoxDecoration(
        color: Color(0xFF8E44B9),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "New",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          NotificationTile(
            username: "karennne",
            message: "liked your video.",
            time: "1h",
            profileImage: AppAssets.newprofile,
            postImage: AppAssets.today,
          ),
        ],
      ),
    );
  }
}
