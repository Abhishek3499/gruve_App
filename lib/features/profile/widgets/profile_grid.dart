import 'package:flutter/material.dart';
import '../../../core/assets.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(images[index], fit: BoxFit.cover),
        );
      },
    );
  }
}
