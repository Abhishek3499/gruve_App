import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/gift_button.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/subscribe_button.dart';

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔥 Top Row (Back Button)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Image.asset(
                  AppAssets.back,
                  width: 22,
                  height: 22,
                  color: Colors.white, // agar white tint chahiye
                ),
              ),
              const Spacer(),
            ],
          ),
        ),

        const SizedBox(height: 30),

        /// 🔥 Avatar + Info Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7D63D1).withValues(alpha: 0.8),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7D63D1).withValues(alpha: 0.6),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(AppAssets.profile),
                ),
              ),

              const SizedBox(width: 25),

              /// Name + Username + Buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 10),

                    Text(
                      "Anastasia Adams",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "__@nastasia__",
                      style: TextStyle(color: Color(0xFF9544A7), fontSize: 14),
                    ),

                    SizedBox(height: 16),

                    Row(
                      children: [
                        SubscribeButton(),
                        SizedBox(width: 21),
                        GiftButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
