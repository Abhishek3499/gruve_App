import 'package:flutter/material.dart';
import 'package:gruve_app/api_calls/profile/controller/profile_controller.dart';
import 'package:gruve_app/features/camera/camera_handler.dart';
import 'package:gruve_app/features/home/post_share_flow_bridge.dart';

class StoryList extends StatefulWidget {
  final ProfileController controller;

  const StoryList({super.key, required this.controller});

  @override
  State<StoryList> createState() => _StoryListState();
}

class _StoryListState extends State<StoryList> {
  @override
  Widget build(BuildContext context) {
    final stories =
        widget.controller.storyList.value; // 👈 IMPORTANT - using ValueNotifier

    debugPrint("📦 StoryList count: ${stories.length}");

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 30),
        itemCount: 1 + stories.length, // 🔥 FIX
        itemBuilder: (context, index) {
          /// ➕ ADD STORY (FIRST ITEM)
          if (index == 0) {
            return _buildAddStory(context);
          }

          /// 👤 USER STORIES
          final story = stories[index - 1];
          return _buildStoryItem(context, story);
        },
      ),
    );
  }

  /// ➕ ADD STORY BUTTON
  Widget _buildAddStory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () async {
          debugPrint('➕ [StoryList] Add Story tapped');

          final result = await CameraHandler.openCamera(context);

          debugPrint("📸 Camera result: $result");

          // If camera returns a media path, add it as a story
          if (result != null && result is String && result.isNotEmpty) {
            debugPrint('📸 [StoryList] Adding story from camera: $result');
            widget.controller.addStory(imageUrl: result);
          }

          if (result == 'start_processing' && context.mounted) {
            PostShareFlowBridge.notifyShareStartProcessing();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
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
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add Story',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 STORY ITEM (DYNAMIC)
  Widget _buildStoryItem(BuildContext context, dynamic story) {
    final imageUrl = story.imageUrl ?? "";
    final username = story.username ?? "User";
    final hasSeen = story.hasSeen ?? false;

    debugPrint("👀 Story: $username | seen: $hasSeen");

    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: () {
          debugPrint("📖 Open Story ID: ${story.id}");

          /// 👉 Yaha story viewer open karega
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasSeen
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFD42BC2), Color(0xFF6BA9F6)],
                      ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.white),
                        )
                      : const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              username,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
