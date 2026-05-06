import 'package:flutter/material.dart';
import 'app_shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FeedShimmer — full-screen skeleton for the video feed initial load.
//
// WHY THIS MATTERS:
//   The current home feed shows a plain CircularProgressIndicator on a black
//   screen. Users have no idea what's loading or how long it will take.
//   This skeleton mirrors the EXACT layout of a real video card — the user
//   immediately understands the structure of what's coming.
//
// LAYOUT MIRRORS:
//   - Full dark background (video area)
//   - Bottom-left: avatar + username + caption lines (VideoUserInfo)
//   - Bottom-right: action bar icons (RightActionBar)
//   - Top: tab bar area
// ─────────────────────────────────────────────────────────────────────────────
class FeedShimmer extends StatelessWidget {
  const FeedShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AppShimmer(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // ── Video background placeholder ──────────────────────────────
            Container(
              width: size.width,
              height: size.height,
              color: const Color(0xFF1A0A22),
            ),

            // ── Top tab bar area (For You / Following) ────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  ShimmerBox(width: 60, height: 14, borderRadius: 6),
                  SizedBox(width: 24),
                  ShimmerBox(width: 70, height: 14, borderRadius: 6),
                ],
              ),
            ),

            // ── Bottom-left: user info + caption ─────────────────────────
            Positioned(
              left: 16,
              right: 90,
              bottom: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  // Avatar + username row
                  Row(
                    children: [
                      ShimmerCircle(radius: 18),
                      SizedBox(width: 10),
                      ShimmerBox(width: 110, height: 13, borderRadius: 6),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Caption line 1
                  ShimmerBox(width: double.infinity, height: 12, borderRadius: 5),
                  SizedBox(height: 6),
                  // Caption line 2 (shorter — realistic text shape)
                  ShimmerBox(width: 200, height: 12, borderRadius: 5),
                  SizedBox(height: 10),
                  // Music row
                  Row(
                    children: [
                      ShimmerCircle(radius: 8),
                      SizedBox(width: 6),
                      ShimmerBox(width: 130, height: 11, borderRadius: 5),
                    ],
                  ),
                ],
              ),
            ),

            // ── Bottom-right: action bar ──────────────────────────────────
            Positioned(
              right: 16,
              bottom: 140,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  ShimmerCircle(radius: 22),
                  SizedBox(height: 6),
                  ShimmerBox(width: 28, height: 10, borderRadius: 4),
                  SizedBox(height: 18),
                  ShimmerCircle(radius: 22),
                  SizedBox(height: 6),
                  ShimmerBox(width: 28, height: 10, borderRadius: 4),
                  SizedBox(height: 18),
                  ShimmerCircle(radius: 22),
                  SizedBox(height: 6),
                  ShimmerBox(width: 28, height: 10, borderRadius: 4),
                  SizedBox(height: 18),
                  ShimmerCircle(radius: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
