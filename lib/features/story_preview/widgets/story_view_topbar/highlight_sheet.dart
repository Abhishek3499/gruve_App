import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/highlights_create/controller/highlight_create_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/story_preview/controllers/story_playback_controller.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_selector_screen.dart';

void showInstagramHighlightSheet(BuildContext context) {
  final playbackController = StoryPlaybackController();
  StoryStateController.ensureRegistered();
  final storyStateController = Get.find<StoryStateController>();

  debugPrint('[HighlightSheet] Opening sheet -> Pause Story');

  final currentStory = storyStateController.currentStory;
  debugPrint(
    '[HighlightSheet] Current story when opening sheet: '
    '${currentStory?.id ?? 'NULL'}',
  );

  if (currentStory == null) {
    debugPrint('[HighlightSheet] ERROR: cannot open sheet without currentStory');
    return;
  }

  if (currentStory.id.isEmpty) {
    debugPrint('[HighlightSheet] ERROR: cannot open sheet with empty story id');
    return;
  }

  playbackController.pauseStory(reason: 'Highlight Sheet Open');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const HighlightSheetContent(),
  ).then((_) {
    debugPrint('[HighlightSheet] Sheet closed -> Resume Story');
    playbackController.resumeStory(reason: 'Highlight Sheet Closed');
    
    // Refresh highlights after sheet closes to get updated data
    final highlightController = Get.find<HighlightController>();
    highlightController.fetchMyHighlights();
  });
}

class HighlightSheetContent extends StatefulWidget {
  const HighlightSheetContent({super.key});

  @override
  State<HighlightSheetContent> createState() => _HighlightSheetContentState();
}

class _HighlightSheetContentState extends State<HighlightSheetContent> {
  int selectedIndex = -1;

  final HighlightController _highlightController =
      Get.isRegistered<HighlightController>()
          ? Get.find<HighlightController>()
          : Get.put(HighlightController());

  final HighlightCreateController _createController = Get.put(
    HighlightCreateController(),
  );

  late final StoryStateController _storyStateController;

  @override
  void initState() {
    super.initState();
    StoryStateController.ensureRegistered();
    HighlightStateManager.ensureRegistered();
    _storyStateController = Get.find<StoryStateController>();
    debugPrint('[HighlightSheet] initState - Fetching highlights');

    final currentStory = _storyStateController.currentStory;
    debugPrint(
      '[HighlightSheet] Current story on init: ${currentStory?.id ?? 'NULL'}',
    );

    _highlightController.fetchMyHighlights();
  }

  bool _isStoryAlreadyAdded(HighlightModel highlight) {
    final currentStory = _storyStateController.currentStory;
    if (currentStory == null || currentStory.id.isEmpty) return false;
    return highlight.containsStory(currentStory.id);
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
                  final isAlreadyAdded = _isStoryAlreadyAdded(highlight);

                  return GestureDetector(
                    onTap: () {
                      if (isAlreadyAdded) {
                        debugPrint(
                          '[HighlightSheet] Duplicate detected: '
                          'highlight_id=${highlight.id}, '
                          'story_id=${_storyStateController.currentStory?.id}',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Already added')),
                        );
                      }

                      debugPrint(
                        '[HighlightSheet] Highlight tapped - selection only',
                      );
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
                      onPressed: _isSelectedStoryAlreadyAdded()
                          ? null
                          : () async {
                              debugPrint(
                                '[HighlightSheet] Done button pressed',
                              );

                              final currentStory =
                                  _storyStateController.currentStory;
                              debugPrint(
                                '[HighlightSheet] Current story on Done: '
                                '${currentStory?.id ?? 'NULL'}',
                              );

                              if (currentStory == null) {
                                debugPrint(
                                  '[HighlightSheet] ERROR: currentStory is null',
                                );
                                return;
                              }

                              if (currentStory.id.isEmpty) {
                                debugPrint(
                                  '[HighlightSheet] ERROR: currentStory.id is empty',
                                );
                                return;
                              }

                              if (selectedIndex < 0 ||
                                  selectedIndex >=
                                      _highlightController.highlights.length) {
                                debugPrint(
                                  '[HighlightSheet] Invalid index: '
                                  '$selectedIndex, highlights count: '
                                  '${_highlightController.highlights.length}',
                                );
                                return;
                              }

                              final highlight =
                                  _highlightController.highlights[selectedIndex];

                              debugPrint('[HighlightSheet] API Request Data:');
                              debugPrint(
                                '[HighlightSheet] highlight_id: ${highlight.id}',
                              );
                              debugPrint(
                                '[HighlightSheet] story_id: ${currentStory.id}',
                              );
                              debugPrint(
                                '[HighlightSheet] story_media: '
                                '${currentStory.mediaUrl}',
                              );

                              await _createController.addStoryToHighlight(
                                highlightId: highlight.id,
                                storyId: currentStory.id,
                              );

                              if (_createController.isSuccess.value) {
                                debugPrint(
                                  '[HighlightSheet] API call successful',
                                );
                                
                                // IMMEDIATELY update global state - this triggers UI rebuild
                                final stateManager = HighlightStateManager.instance;
                                stateManager.addHighlightedStory(currentStory.id);
                                debugPrint('[HighlightSheet] State updated immediately for story: ${currentStory.id}');
                                
                                Navigator.pop(context);
                                
                                // Refresh highlights for consistency (non-blocking)
                                _highlightController.fetchMyHighlights();
                              } else {
                                debugPrint(
                                  '[HighlightSheet] API call failed: '
                                  '${_createController.message.value}',
                                );
                                if (mounted &&
                                    _createController.message.value.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _createController.message.value,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      child: Text(
                        _isSelectedStoryAlreadyAdded()
                            ? 'Already added'
                            : 'Done',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  bool _isSelectedStoryAlreadyAdded() {
    if (selectedIndex < 0 ||
        selectedIndex >= _highlightController.highlights.length) {
      return false;
    }

    return _isStoryAlreadyAdded(_highlightController.highlights[selectedIndex]);
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              debugPrint('[HighlightSheet] Navigating to CreateHighlightSheet');

              final currentStory = _storyStateController.currentStory;

              if (currentStory == null) {
                debugPrint('[HighlightSheet] ERROR: No story selected');
                return;
              }

              if (currentStory.id.isEmpty) {
                debugPrint('[HighlightSheet] ERROR: currentStory.id is empty');
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
            'New',
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
