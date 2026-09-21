import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/shared/widgets/post_grid_thumbnail.dart';
import 'package:gruve_app/features/camera/presentation/controller/camera_handler.dart';
import 'package:gruve_app/features/highlights/presentation/notifiers/highlight_controller_notifier.dart';
import 'package:gruve_app/features/highlights/domain/entities/highlight_model.dart';
import 'package:gruve_app/features/highlights/presentation/screens/highlight_viewer_screen.dart';
import 'package:gruve_app/features/home/presentation/controllers/post_share_flow_bridge.dart';
import 'package:gruve_app/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/core/constants/app_colors.dart';

class StoryList extends ConsumerWidget {
  const StoryList({super.key});

  void _log(String message) {
    AppLogger.d(message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.watch(
      profileNotifierProvider.select((s) => s.errorMessage),
    );

    // Show error state
    if (errorMessage != null) {
      return _buildErrorState(context, ref);
    }

    final highlights = ref.watch(
      profileNotifierProvider.select((s) => s.highlights),
    );

    // Show normal content
    return SizedBox(
      height: 102,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 30),
        itemCount: highlights.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStory(context, ref);
          }

          return _buildHighlightItem(context, ref, highlights[index - 1]);
        },
      ),
    );
  }

  Widget _buildAddStory(BuildContext context, WidgetRef ref, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () async {
          _log('[StoryList] Add Story tapped');

          final result = await CameraHandler.openCamera(context);
          _log('[StoryList] Camera result: $result');

          if (result != null && result is String && result.isNotEmpty) {
            ref
                .read(profileNotifierProvider.notifier)
                .controller
                .addStory(imageUrl: result);
          }

          if (result == 'start_processing' && context.mounted) {
            // For camera flow from story, assume video (most common case)
            PostShareFlowBridge.notifyShareStartProcessing(true);
          }
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HighlightCircle(
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
            SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                'new',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(
    BuildContext context,
    WidgetRef ref,
    HighlightModel highlight,
  ) {
    final cover = highlight.coverPreviewUrl;

    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () {
          _log('[StoryList] Highlight item tapped: ${highlight.title}');
          _log('[StoryList] Highlight ID: ${highlight.id}');
          _log('[StoryList] Stories count: ${highlight.stories.length}');
          _log('[HighlightTap] Navigating to viewer');

          ref
              .read(highlightControllerProvider.notifier)
              .cacheHighlightStories(highlight);
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
                        width: 60,
                        height: 60,
                        fallback: _placeholderIcon(),
                        placeholder: _placeholderIcon(),
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

  Widget _placeholderIcon() {
    return Container(
      width: 60,
      height: 60,
      color: const Color(0xFF212235),
      child: const Icon(Icons.image_outlined, color: Colors.white70),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 102,
      child: Row(
        children: [
          const SizedBox(width: 30),
          // Add Story button (always visible)
          _buildAddStory(context, ref, key: const Key('add_story_error')),
          const SizedBox(width: 18),
          // Error indicator
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.2),
              border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 18),
          // Retry button
          GestureDetector(
            onTap: () {
              _log('[StoryList] Retry tapped');
              ref
                  .read(profileNotifierProvider.notifier)
                  .refreshProfileData(reason: 'story_list_retry');
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.2),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.refresh, color: Colors.blue, size: 24),
            ),
          ),
        ],
      ),
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
          colors: [AppColors.vibrantMagenta, Color(0xFF6BA9F6)],
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
