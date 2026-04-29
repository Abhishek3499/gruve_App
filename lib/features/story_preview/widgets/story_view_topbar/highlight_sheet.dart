import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_selector_screen.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/story_preview/controllers/story_playback_controller.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/highlights_create/controller/highlight_create_controller.dart';
import 'package:get/get.dart';

void showInstagramHighlightSheet(BuildContext context) {
  final playbackController = StoryPlaybackController();

  debugPrint("📱 [HighlightSheet] Opening sheet → Pause Story");
  playbackController.pauseStory(reason: "Highlight Sheet Open");

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const HighlightSheetContent(),
  ).then((_) {
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
  int selectedIndex = -1;

  final HighlightController _highlightController = Get.put(
    HighlightController(),
  );

  final HighlightCreateController _createController = Get.put(
    HighlightCreateController(),
  );

  final StoryStateController _storyStateController = Get.put(
    StoryStateController(),
  );

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
                return const Center(child: CircularProgressIndicator());
              }

              final highlights = _highlightController.highlights;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: highlights.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddButton();
                  }

                  final highlightIndex = index - 1;
                  final highlight = highlights[highlightIndex];
                  final isSelected = selectedIndex == highlightIndex;

                  return GestureDetector(
                    onTap: () {
                      print("👆 Highlight tapped → selection only (NO API)");
                      setState(() {
                        selectedIndex = isSelected ? -1 : highlightIndex;
                      });
                    },
                    child: _buildHighlightThumbnail(highlight, isSelected),
                  );
                },
              );
            }),
          ),

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
                      onPressed: () async {
                        print("✅ Done button pressed → API CALL START");

                        final currentStory = _storyStateController.currentStory;

                        if (currentStory == null) {
                          print("❌ ERROR: currentStory is null");
                          return;
                        }

                        // Safety check for valid index
                        if (selectedIndex < 0 || selectedIndex >= _highlightController.highlights.length) {
                          print("⚠️ Invalid index: $selectedIndex, highlights count: ${_highlightController.highlights.length}");
                          return;
                        }

                        final highlight =
                            _highlightController.highlights[selectedIndex];

                        print("🧪 FIXED Story ID: ${currentStory.id}");

                        await _createController.addStoryToHighlight(
                          highlightId: highlight.id,
                          storyId: currentStory.id,
                        );

                        if (_createController.isSuccess.value) {
                          Navigator.pop(context);
                        }
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

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              print("🚀 Navigating to CreateHighlightSheet");

              final currentStory = _storyStateController.currentStory;

              if (currentStory == null) {
                print("❌ ERROR: No story selected");
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateHighlightSheet(
                    storyImageUrl: currentStory.mediaUrl,
                    storyId: currentStory.id,
                  ),
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
            scale: isSelected ? 0.95 : 1.0,
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
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.collections),
                  ),
                ),
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
                    child: const Icon(Icons.check_circle, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(highlight.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
