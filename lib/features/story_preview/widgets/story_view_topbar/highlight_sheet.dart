import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_selector_screen.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';

class StoryItem {
  final String imageUrl;
  final String emoji;
  StoryItem({required this.imageUrl, required this.emoji});
}

void showInstagramHighlightSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const HighlightSheetContent(),
  );
}

class HighlightSheetContent extends StatefulWidget {
  const HighlightSheetContent({super.key});

  @override
  State<HighlightSheetContent> createState() => _HighlightSheetContentState();
}

class _HighlightSheetContentState extends State<HighlightSheetContent> {
  // Track the selected index (-1 means nothing is selected)
  int selectedIndex = -1;

  final List<StoryItem> myStories = [
    StoryItem(imageUrl: 'https://picsum.photos/200/300?random=1', emoji: '🏔️'),
    StoryItem(imageUrl: 'https://picsum.photos/200/300?random=2', emoji: '❗'),
    StoryItem(imageUrl: 'https://picsum.photos/200/300?random=3', emoji: '🔥'),
  ];

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
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // itemCount + 1 to account for the leading Add button
              itemCount: myStories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // 1. The Add Button (First Item)
                  return _buildAddButton();
                }

                // 2. The Story Items (Offset by 1)
                final storyIndex = index - 1;
                final item = myStories[storyIndex];
                final isSelected = selectedIndex == storyIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      // Toggle selection or select new
                      selectedIndex = isSelected ? -1 : storyIndex;
                    });
                  },
                  child: _buildHighlightThumbnail(item, isSelected),
                );
              },
            ),
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
                      onPressed: () => Navigator.pop(context),
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
            onTap: () {
              final storyStateController = StoryStateController();
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

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) =>
                    CreateHighlightSheet(storyImageUrl: currentStoryUrl),
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

  Widget _buildHighlightThumbnail(StoryItem item, bool isSelected) {
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
                  child: Image.network(
                    item.imageUrl,
                    height: 180,
                    width: 130,
                    fit: BoxFit.cover,
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
          Text(item.emoji, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
