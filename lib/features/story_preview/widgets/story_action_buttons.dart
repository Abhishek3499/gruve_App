import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';

class StoryActionButtons extends StatelessWidget {
  StoryActionButtons({super.key});

  final GlobalKey _moreKey = GlobalKey();

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

        // ✅ MORE BUTTON
        _buildActionButton(
          Image.asset(AppAssets.extradots, color: Colors.white),
          "More",
          size: 22,
          key: _moreKey,
          onTap: () {
            final RenderBox renderBox =
                _moreKey.currentContext!.findRenderObject() as RenderBox;

            final position = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;

            showMenu(
              context: context,
              position: RelativeRect.fromLTRB(
                position.dx,
                position.dy + size.height + 8,
                position.dx + size.width,
                0,
              ),
              color: const Color.fromARGB(255, 80, 33, 86),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // 👈 cleaner radius
              ),
              items: [
                _popupItem(AppAssets.draw, 'Draw'),
                _popupItem(AppAssets.saves, 'Save'),
                _popupItem(AppAssets.turnoff, 'Turn off commenting'),
              ],
            );
          },
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
  PopupMenuItem _popupItem(String assetPath, String text) {
    return PopupMenuItem(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Image.asset(
            assetPath,
            color: Colors.white, // 👈 white tint
            width: 18,
            height: 18,
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
