import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile/data/models/user_model.dart';
import '../../../../core/constants/app_colors.dart';

class StatsRow extends StatelessWidget {
  final UserModel user;

  const StatsRow({super.key, required this.user});

  Widget buildStat(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.white70, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildStat(user.followers.toString(), "Followers"),
        buildStat(user.likes.toString(), "Likes"),
        buildStat(user.videos.toString(), "Videos"),
      ],
    );
  }
}
