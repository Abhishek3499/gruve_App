import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/profile/controller/profile_controller.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/highlights/screens/highlight_viewer_screen.dart';
import 'package:gruve_app/widgets/user_profile_story_skeleton.dart';

/// Reusable highlights list for user profile
/// Similar to StoryList but without "Add Story" button
class UserHighlightsList extends StatelessWidget {
  final List<HighlightModel> highlights;
  final bool isOwnProfile;
  final ProfileController? controller;

  const UserHighlightsList({
    super.key,
    required this.highlights,
    this.isOwnProfile = false,
    this.controller,
  });

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    _log('[UserHighlightsList] Building with ${highlights.length} highlights');
    _log('[UserHighlightsList] isOwnProfile: $isOwnProfile');
    
    // Check if we should show skeleton loader
    final isLoading = controller?.isLoading.value ?? false;
    _log('[UserHighlightsList] isLoading: $isLoading');
    
    // Show skeleton loader while loading
    if (isLoading) {
      _log('[UserHighlightsList] Showing skeleton loader');
      return const UserProfileStorySkeleton(itemCount: 6);
    }

    // Hide if no highlights
    if (highlights.isEmpty) {
      _log('[UserHighlightsList] No highlights, returning empty widget');
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 102,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 30),
        itemCount: highlights.length,
        itemBuilder: (context, index) {
          return _buildHighlightItem(context, highlights[index]);
        },
      ),
    );
  }

  Widget _buildHighlightItem(BuildContext context, HighlightModel highlight) {
    final cover = _coverFor(highlight);

    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () {
          _log('[UserHighlightsList] Highlight tapped: ${highlight.title}');
          _log('[UserHighlightsList] Highlight ID: ${highlight.id}');
          _log('[UserHighlightsList] Stories count: ${highlight.stories.length}');
          _log('[UserHighlightsList] Navigating to viewer');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HighlightViewerScreen(highlightId: highlight.id),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HighlightCircle(
              child: ClipOval(
                child: cover != null
                    ? Image.network(
                        cover,
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholderIcon(),
                      )
                    : _placeholderIcon(),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                highlight.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _coverFor(HighlightModel highlight) {
    if (highlight.coverMediaUrl.trim().isNotEmpty) {
      return highlight.coverMediaUrl.trim();
    }

    if (highlight.stories.isNotEmpty &&
        highlight.stories.first.mediaUrl.trim().isNotEmpty) {
      return highlight.stories.first.mediaUrl.trim();
    }

    return null;
  }

  Widget _placeholderIcon() {
    return Container(
      width: 60,
      height: 60,
      color: const Color(0xFF212235),
      child: const Icon(Icons.image_outlined, color: Colors.white70),
    );
  }
}

class _HighlightCircle extends StatelessWidget {
  final Widget child;

  const _HighlightCircle({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF212235),
        ),
        child: ClipOval(child: child),
      ),
    );
  }
}
