import 'package:flutter/material.dart';
import 'app_shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchResultsShimmer — skeleton for user search results.
//
// WHY THIS MATTERS:
//   Currently the search page shows a CircularProgressIndicator while
//   searching. This skeleton shows user rows so the user knows results
//   are coming. It also prevents the jarring jump from spinner → list.
//
// LAYOUT MIRRORS:
//   Each row = avatar + (name + username lines)
//   Matches the ListTile layout in search_page.dart.
// ─────────────────────────────────────────────────────────────────────────────
class SearchResultsShimmer extends StatelessWidget {
  final int itemCount;

  const SearchResultsShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, index) => _SearchRowSkeleton(
          nameWidth: index % 3 == 0 ? 130.0 : (index % 3 == 1 ? 100.0 : 115.0),
        ),
      ),
    );
  }
}

class _SearchRowSkeleton extends StatelessWidget {
  final double nameWidth;

  const _SearchRowSkeleton({required this.nameWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const ShimmerCircle(radius: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: nameWidth, height: 13, borderRadius: 5),
              const SizedBox(height: 6),
              const ShimmerBox(width: 80, height: 11, borderRadius: 5),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RecentSearchShimmer — skeleton for recent searches section while loading
// from local storage on screen open.
// ─────────────────────────────────────────────────────────────────────────────
class RecentSearchShimmer extends StatelessWidget {
  final int itemCount;

  const RecentSearchShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Recent" title placeholder
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ShimmerBox(width: 70, height: 16, borderRadius: 6),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: (_, index) => _SearchRowSkeleton(
              nameWidth: 100.0 + (index * 15.0),
            ),
          ),
        ],
      ),
    );
  }
}
