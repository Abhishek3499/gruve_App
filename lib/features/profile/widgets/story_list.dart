import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/camera_handler.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/highlights/screens/highlight_viewer_screen.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';
import 'package:gruve_app/widgets/story_list_skeleton.dart';

class StoryList extends StatelessWidget {
  final ProfileProvider provider;

  const StoryList({super.key, required this.provider});

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    _log('[StoryList] Building with isLoading: ${provider.isLoading}');
    
    // Show skeleton loader while loading
    if (provider.isLoading) {
      _log('[StoryList] Showing skeleton loader with Add Story button');
      return Row(
        children: [
          const SizedBox(width: 30),
          // Show actual Add Story button during loading
          _buildAddStory(context),
          // Show skeleton for other users' stories
          Expanded(
            child: const StoryListSkeleton(otherUsersCount: 6),
          ),
        ],
      );
    }

    // Show error state
    if (provider.errorMessage != null) {
      _log('[StoryList] Showing error state: ${provider.errorMessage}');
      return _buildErrorState(context);
    }

    final highlights = provider.highlights;
    _log('[Profile] Highlights row count: ${highlights.length}');

    // Show empty state
    if (highlights.isEmpty) {
      _log('[StoryList] Showing empty state');
      return _buildEmptyState(context);
    }

    // Show normal content
    return SizedBox(
      height: 102,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 30),
        itemCount: highlights.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStory(context);
          }

          return _buildHighlightItem(context, highlights[index - 1]);
        },
      ),
    );
  }

  Widget _buildAddStory(BuildContext context, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () async {
          _log('[StoryList] Add Story tapped');

          final result = await CameraHandler.openCamera(context);
          _log('[StoryList] Camera result: $result');

          if (result != null && result is String && result.isNotEmpty) {
            provider.controller.addStory(imageUrl: result);
          }

          if (result == 'start_processing' && context.mounted) {
            PostShareFlowBridge.notifyShareStartProcessing();
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
                'Add Story',
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

  Widget _buildHighlightItem(BuildContext context, HighlightModel highlight) {
    final cover = _coverFor(highlight);

    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () {
          _log('[StoryList] Highlight item tapped: ${highlight.title}');
          _log('[StoryList] Highlight ID: ${highlight.id}');
          _log('[StoryList] Stories count: ${highlight.stories.length}');
          _log('[HighlightTap] Navigating to viewer');

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

  Widget _buildErrorState(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Row(
        children: [
          const SizedBox(width: 30),
          // Add Story button (always visible)
          _buildAddStory(context, key: const Key('add_story_error')),
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
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 18),
          // Retry button
          GestureDetector(
            onTap: () {
              _log('[StoryList] Retry tapped');
              provider.refreshProfileData(reason: 'story_list_retry');
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.2),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.blue,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Row(
        children: [
          const SizedBox(width: 30),
          // Add Story button (always visible)
          _buildAddStory(context, key: const Key('add_story_empty')),
          const SizedBox(width: 18),
          // Empty state indicator
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withValues(alpha: 0.2),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
            ),
            child: const Icon(
              Icons.highlight_off,
              color: Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No highlights',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Create your first highlight',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
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
