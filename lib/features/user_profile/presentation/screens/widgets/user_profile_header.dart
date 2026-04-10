import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/gifts/widgets/gift_panel.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/gift_button.dart';
import 'package:gruve_app/features/user_profile/presentation/screens/widgets/subscribe_button.dart';

class UserProfileHeader extends StatelessWidget {
  final String displayName;
  final String username;
  final String? profileImageUrl;
  final bool showSubscribeButton;
  final bool reserveSubscribeSpace;

  const UserProfileHeader({
    super.key,
    required this.displayName,
    required this.username,
    this.profileImageUrl,
    required this.showSubscribeButton,
    this.reserveSubscribeSpace = false,
  });

  ImageProvider _profileImageProvider() {
    if (profileImageUrl != null &&
        profileImageUrl!.isNotEmpty &&
        profileImageUrl!.startsWith('http')) {
      return NetworkImage(profileImageUrl!);
    }

    return AssetImage(AppAssets.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  color: Colors.white,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  backgroundImage: _profileImageProvider(),
                ),
              ),
              const SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Color(0xFF9544A7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (showSubscribeButton) ...[
                          const SubscribeButton(),
                          const SizedBox(width: 21),
                        ] else if (reserveSubscribeSpace) ...[
                          const SizedBox(width: 132, height: 42),
                          const SizedBox(width: 21),
                        ],
                        GiftButton(
                          onTap: () {
                            debugPrint("Gift Button Tapped!");
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const GiftPanel(),
                            );
                          },
                        ),
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
