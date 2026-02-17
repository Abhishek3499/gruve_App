import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import '../widgets/notification_tile.dart';
import '../widgets/follow_tile.dart';

class ThisWeekSection extends StatelessWidget {
  const ThisWeekSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF511263),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
      ),
      child: Column(
        children: [
          const NotificationTile(
            username: "craig_love",
            message: "mentioned you in a comment.",
            time: "2d",
            profileImage: AppAssets.thisweek,
            postImage: AppAssets.today,
          ),
          const FollowTile(
            username: "martini_rond",
            time: "3d",
            profileImage: AppAssets.frame2,
          ),
          const FollowTile(
            username: "maxjacobson",
            time: "3d",
            profileImage: AppAssets.frame1,
          ),
        ],
      ),
    );
  }
}
