import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class HorizontalImageList extends StatelessWidget {
  final List<String> imageList;
  final double height;
  final double itemWidth;
  final double borderRadius;

  const HorizontalImageList({
    super.key,
    required this.imageList,
    this.height = 200,
    this.itemWidth = 130,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: imageList.length,
        itemBuilder: (context, index) {
          return Container(
            width: itemWidth,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.grey[300],
              image: DecorationImage(
                image: AssetImage(imageList[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Dummy data for horizontal list
class DummyImageList {
  static List<String> getImages() {
    return [
      AppAssets.user, // Using user asset as dummy
      AppAssets.user,
      AppAssets.user,
      AppAssets.user,
      AppAssets.user,
      AppAssets.user,
    ];
  }
}
