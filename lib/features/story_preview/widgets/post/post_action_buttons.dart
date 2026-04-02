import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/features/story_preview/screens/post/more_option_screen.dart';

class PostActionButtons extends StatelessWidget {
  const PostActionButtons({super.key});

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
        const SizedBox(width: 13),

        _buildActionButton(
          Image.asset(AppAssets.text, color: Colors.white),
          "Aa",
          size: 22,
        ),
        const SizedBox(width: 13),

        _buildActionButton(
          Image.asset(AppAssets.musics, color: Colors.white),
          "Music",
          size: 22,
        ),
        const SizedBox(width: 13),

        _buildActionButton(
          Image.asset(AppAssets.filter, color: Colors.white),
          "Filter",
          size: 22,
        ),
        const SizedBox(width: 13),
        _buildActionButton(
          Image.asset(AppAssets.cuts, color: Colors.white),
          "Trim",
          size: 22,
        ),
        const SizedBox(width: 13),
        _buildActionButton(
          Image.asset(AppAssets.download2, color: Colors.white),
          "Download",
          size: 22,
        ),
        const SizedBox(width: 13),
        _buildActionButton(
          Image.asset(AppAssets.gallery2, color: Colors.white),
          "Gallery",
          size: 22,
        ),
        const SizedBox(width: 13),

        // ✅ MORE BUTTON
        _buildActionButton(
          const Icon(Icons.more_horiz, color: Colors.white),
          "More",
          size: 22,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MoreOptionScreen()),
          ),
        ),
      ],
    );
  }

  // ✅ BUTTON BUILDER
  Widget _buildActionButton(
    Widget icon,
    String tooltip, {
    double size = 18,
    VoidCallback? onTap,
    Key? key,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        key: key,
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white24,
          ),
          child: SizedBox(width: size, height: size, child: icon),
        ),
      ),
    );
  }

  // 🔥 COMPACT POPUP ITEM (HEIGHT FIXED HERE)
}
