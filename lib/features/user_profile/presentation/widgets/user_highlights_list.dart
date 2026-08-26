import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/shared/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/features/profile/presentation/controller/profile_controller.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';
import 'package:gruve_app/features/highlights/presentation/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/presentation/screens/highlight_viewer_screen.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';

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
    AppLogger.d(message);
  }

  @override
  Widget build(BuildContext context) {
    _log('[UserHighlightsList] Building with ${highlights.length} highlights');
    _log('[UserHighlightsList] isOwnProfile: $isOwnProfile');

    if (highlights.isEmpty) {
      _log('[UserHighlightsList] No highlights, returning empty widget');
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: context.rh(102),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: context.rw(30)),
        itemCount: highlights.length,
        itemBuilder: (context, index) {
          return _buildHighlightItem(context, highlights[index]);
        },
      ),
    );
  }

  Widget _buildHighlightItem(BuildContext context, HighlightModel highlight) {
    final cover = highlight.coverPreviewUrl;

    return Padding(
      padding: EdgeInsets.only(right: context.rw(18)),
      child: GestureDetector(
        onTap: () {
          _log('[UserHighlightsList] Highlight tapped: ${highlight.title}');
          context.read<HighlightController>().cacheHighlightStories(highlight);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HighlightViewerScreen(
                highlightId: highlight.id,
                initialHighlight: highlight,
              ),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HighlightCircle(
              child: ClipOval(
                child: cover != null
                    ? MediaUrlThumbnail(
                        url: cover,
                        width: context.rw(60),
                        height: context.rh(60),
                        fallback: _placeholderIcon(),
                        placeholder: _placeholderIcon(),
                      )
                    : _placeholderIcon(),
              ),
            ),
            SizedBox(height: context.rh(6)),
            SizedBox(
              width: context.rw(72),
              child: Text(
                highlight.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: context.rf(12)),
              ),
            ),
          ],
        ),
      ),
    );
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
      width: context.rw(64),
      height: context.rh(64),
      padding: EdgeInsets.all(context.rw(2)),
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
