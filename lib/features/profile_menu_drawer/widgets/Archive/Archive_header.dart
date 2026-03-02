import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class ArchiveHeader extends StatelessWidget {
  const ArchiveHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset(AppAssets.back, width: 25, height: 25),
            ),
          ),

          // Title
          const Text(
            "Archive",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'syncopate',
            ),
          ),
        ],
      ),
    );
  }
}
