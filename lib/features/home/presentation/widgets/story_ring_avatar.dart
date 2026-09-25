import 'package:flutter/material.dart';

/// Wraps a feed post's avatar with an Instagram-style story ring.
///
/// [hasUnseenStory] is the sole gate for ring visibility here — the moment
/// it's false, no ring shows at all, regardless of [hasCloseFriendsStory].
/// The caller's tap handler mirrors this same gate (no navigation once
/// unseen is false), unlike the profile avatar which keeps a faded,
/// still-tappable ring for the already-viewed case.
class StoryRingAvatar extends StatelessWidget {
  final Widget avatar;
  final bool hasUnseenStory;
  final bool hasCloseFriendsStory;
  final VoidCallback? onTap;
  final double ringWidth;
  final double ringGap;

  const StoryRingAvatar({
    super.key,
    required this.avatar,
    this.hasUnseenStory = false,
    this.hasCloseFriendsStory = false,
    this.onTap,
    this.ringWidth = 2.0,
    this.ringGap = 2.0,
  });

  Gradient? get _ringGradient {
    if (!hasUnseenStory) return null;

    if (hasCloseFriendsStory) {
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF6DD400), Color(0xFF2ECC40), Color(0xFF00C853)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFFFEDA75),
        Color(0xFFFA7E1E),
        Color(0xFFD62976),
        Color(0xFF962FBF),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ringGradient = _ringGradient;

    final content = ringGradient == null
        ? avatar
        : Container(
            padding: EdgeInsets.all(ringWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ringGradient,
            ),
            child: Container(
              padding: EdgeInsets.all(ringGap),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF130722),
              ),
              child: avatar,
            ),
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}
