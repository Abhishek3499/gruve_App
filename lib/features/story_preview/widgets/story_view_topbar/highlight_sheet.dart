import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_selector_screen.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/story_preview/controllers/story_playback_controller.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:get/get.dart';

void showInstagramHighlightSheet(BuildContext context) {
  final playbackController = StoryPlaybackController();
  
  // Pause story when sheet opens
  debugPrint("📱 [HighlightSheet] Opening sheet → Pause Story");
  playbackController.pauseStory(reason: "Highlight Sheet Open");
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const HighlightSheetContent(),
  ).then((_) {
    // Resume story when sheet closes
    debugPrint("📱 [HighlightSheet] Sheet closed → Resume Story");
    playbackController.resumeStory(reason: "Highlight Sheet Closed");
  });
}

class HighlightSheetContent extends StatefulWidget {
  const HighlightSheetContent({super.key});

  @override
  State<HighlightSheetContent> createState() => _HighlightSheetContentState();
}

class _HighlightSheetContentState extends State<HighlightSheetContent> {
  // Track the selected index (-1 means nothing is selected)
  int selectedIndex = -1;

  // HighlightController instance
  final HighlightController _highlightController = Get.put(HighlightController());
  
  // Playback controller
  final StoryPlaybackController _playbackController = StoryPlaybackController();

  @override
  void initState() {
    super.initState();
    debugPrint("📱 [HighlightSheet] initState - Fetching highlights");
    _highlightController.fetchMyHighlights();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Add to highlights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(
            height: 250,
            child: Obx(() {
              if (_highlightController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final highlights = _highlightController.highlights;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // itemCount + 1 to account for the leading Add button
                itemCount: highlights.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // 1. The Add Button (First Item)
                    return _buildAddButton();
                  }

                  // 2. The Highlight Items (Offset by 1)
                  final highlightIndex = index - 1;
                  final highlight = highlights[highlightIndex];
                  final isSelected = selectedIndex == highlightIndex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        // Toggle selection or select new
                        selectedIndex = isSelected ? -1 : highlightIndex;
                      });
                    },
                    child: _buildHighlightThumbnail(highlight, isSelected),
                  );
                },
              );
            }),
          ),

          // Bottom Action Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: selectedIndex != -1 ? 80 : 30,
            child: selectedIndex != -1
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        debugPrint("📱 [HighlightSheet] Done button pressed");
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Update this in your current file
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final storyStateController = StoryStateController();
              
              // Load stories from storage before accessing
              await storyStateController.loadStoriesFromStorage(null);
              
              final mediaPaths =
                  storyStateController.currentUserStoryMediaPaths;

              if (mediaPaths.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No stories available')),
                );
                return;
              }

              // 👉 Direct first story ya current story
              final currentStoryUrl = mediaPaths.first;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateHighlightSheet(storyImageUrl: currentStoryUrl),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 180,
              width: 130,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: const Icon(Icons.add, size: 40, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "New",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightThumbnail(HighlightModel highlight, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          AnimatedScale(
            scale: isSelected
                ? 0.95
                : 1.0, // Slight shrink animation when selected
            duration: const Duration(milliseconds: 200),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 180,
                    width: 130,
                    color: Colors.grey[300],
                    child: highlight.coverMediaUrl != null
                        ? Image.network(
                            highlight.coverMediaUrl!,
                            height: 180,
                            width: 130,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.collections, size: 40, color: Colors.grey);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                          )
                        : const Icon(Icons.collections, size: 40, color: Colors.grey),
                  ),
                ),
                // Smooth Selection Overlay
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    height: 180,
                    width: 130,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            highlight.title,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
