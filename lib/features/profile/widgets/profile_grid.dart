import 'package:flutter/material.dart';

import '../../../core/assets.dart';
import '../screens/real_draft_screen.dart';

class ProfileGrid extends StatelessWidget {
  final int selectedTab;

  const ProfileGrid({super.key, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    if (selectedTab == 2) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              color: Colors.white,
              size: 34,
            ),
            SizedBox(height: 12),
            Text(
              'No liked posts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Posts you like will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    List<String> images;

    if (selectedTab == 0) {
      images = [AppAssets.frame1, AppAssets.frame2, AppAssets.frame3];
    } else {
      images = [AppAssets.frame2, AppAssets.frame3];
    }

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
        final isDraftItem = selectedTab == 0 && index == 0;

        return GestureDetector(
          onTap: () {
            if (isDraftItem) {
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
                Image.asset(images[index], fit: BoxFit.cover),
                if (isDraftItem)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: const Text(
                      'Drafts',
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
