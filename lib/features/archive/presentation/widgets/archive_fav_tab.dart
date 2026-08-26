import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class ArchiveFavTab extends StatelessWidget {
  const ArchiveFavTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft, // 👈 top + left
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          top: 20,
        ), // 👈 top spacing control
        child: Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: CircleAvatar(backgroundImage: AssetImage(AppAssets.profile)),
          ),
        ),
      ),
    );
  }
}
