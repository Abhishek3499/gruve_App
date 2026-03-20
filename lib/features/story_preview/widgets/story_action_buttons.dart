import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class StoryActionButtons extends StatelessWidget {
  const StoryActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          const Icon(Icons.volume_up, color: Colors.white),
          "Volume",
          size: 28,
        ),
        const SizedBox(width: 15),

        _buildActionButton(
          Image.asset(AppAssets.text, color: Colors.white),
          "Aa",
          size: 22,
        ),
        const SizedBox(width: 15),

        _buildActionButton(
          Image.asset(AppAssets.musics, color: Colors.white),
          "Music",
          size: 22,
        ),
        const SizedBox(width: 15),

        _buildActionButton(
          Image.asset(AppAssets.filter, color: Colors.white),
          "Effects",
          size: 22,
        ),
        const SizedBox(width: 15),

        _buildActionButton(
          Image.asset(AppAssets.extradots, color: Colors.white),
          "More",
          size: 22,
        ),
      ],
    );
  }

  Widget _buildActionButton(Widget icon, String tooltip, {double size = 18}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white24,
        ),
        child: SizedBox(width: size, height: size, child: icon),
      ),
    );
  }
}
