import 'package:flutter/material.dart';
import '../../../core/assets.dart';
import '../screens/real_draft_screen.dart';

class ProfileGrid extends StatelessWidget {
  const ProfileGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final images = [
      AppAssets.frame1,
      AppAssets.frame2,
      AppAssets.frame3,
      AppAssets.frame1,
      AppAssets.frame2,
      AppAssets.frame3,
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Navigate to Draft Screen only for the first item (Drafts)
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReelsDraftsScreen(),
                ),
              );
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                /// Image
                Image.asset(images[index], fit: BoxFit.cover),

                /// 🔥 If First Item → Show Draft Overlay
                if (index == 0)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: const Text(
                      "Drafts",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
