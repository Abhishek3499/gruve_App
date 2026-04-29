import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/camera_handler.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';
import 'package:gruve_app/features/profile/provider/profile_provider.dart';

class StoryList extends StatelessWidget {
  final ProfileProvider provider;

  const StoryList({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final highlights = provider.highlights;

    debugPrint('[Profile] Highlights row count: ${highlights.length}');

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

          return _buildHighlightItem(highlights[index - 1]);
        },
      ),
    );
  }

  Widget _buildAddStory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () async {
          debugPrint('[StoryList] Add Story tapped');

          final result = await CameraHandler.openCamera(context);
          debugPrint('[StoryList] Camera result: $result');

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

  Widget _buildHighlightItem(HighlightModel highlight) {
    final cover = _coverFor(highlight);

    return Padding(
      padding: const EdgeInsets.only(right: 18),
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
