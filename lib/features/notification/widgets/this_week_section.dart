import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

import '../widgets/follow_tile.dart';
import '../widgets/notification_tile.dart';

class ThisWeekSection extends StatelessWidget {
  const ThisWeekSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Column(
        children: const [
          _ThisWeekBand(),
          SizedBox(height: 8),
          FollowTile(
            username: "martini_rond",
            time: "3d",
            profileImage: AppAssets.frame2,
            userId: "user_martini_rond",
          ),
          FollowTile(
            username: "maxjacobson",
            time: "3d",
            profileImage: AppAssets.frame1,
            userId: "user_maxjacobson",
          ),
          SizedBox(height: 34),
        ],
      ),
    );
  }
}

class _ThisWeekBand extends StatelessWidget {
  const _ThisWeekBand();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF5A126B),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "This Week",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          NotificationTile(
            username: "craig_love",
            message: "mentioned you in a comment.",
            time: "2d",
            profileImage: AppAssets.thisweek,
            postImage: AppAssets.today,
          ),
        ],
      ),
    );
  }
}
