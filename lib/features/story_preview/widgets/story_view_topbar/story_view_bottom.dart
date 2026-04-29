import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/story_preview/screens/more_screen.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/highlight_sheet.dart';

class StoryViewBottom extends StatefulWidget {
  const StoryViewBottom({super.key});

  @override
  State<StoryViewBottom> createState() => _StoryViewBottomState();
}

class _StoryViewBottomState extends State<StoryViewBottom> {
  late final HighlightController _highlightController;
  late final StoryStateController _storyStateController;
  late final HighlightStateManager _stateManager;

  HighlightModel? _matchedHighlight;
  bool _lastKnownHighlighted = false;

  static const Color _inactiveColor = Colors.white;
  static const Color _selectedColor = AppColors.success;
  static const double _highlightIconSize = 24;

  @override
  void initState() {
    super.initState();
    StoryStateController.ensureRegistered();
    HighlightStateManager.ensureRegistered();
    _storyStateController = Get.find<StoryStateController>();
    _highlightController = Get.isRegistered<HighlightController>()
        ? Get.find<HighlightController>()
        : Get.put(HighlightController());
    _stateManager = HighlightStateManager.instance;

    _storyStateController.addListener(_onStoryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_highlightController.highlights.isEmpty &&
          !_highlightController.isLoading.value) {
        _highlightController.fetchMyHighlights();
      }
    });
  }

  @override
  void dispose() {
    _storyStateController.removeListener(_onStoryChanged);
    super.dispose();
  }

  void _onStoryChanged() {
    if (mounted) {
      setState(() {
        _matchedHighlight = null;
        _lastKnownHighlighted = false;
      });
    }
  }

  bool _isCurrentStoryHighlighted() {
    final currentStory = _storyStateController.currentStory;
    final currentStoryId = currentStory?.id?.toString();

    debugPrint('[HighlightButton] === DEBUG START ===');
    debugPrint('[HighlightButton] Current story object: $currentStory');
    debugPrint('[HighlightButton] Current story ID: $currentStoryId');
    debugPrint(
      '[HighlightButton] Current story media: ${currentStory?.mediaUrl}',
    );
    debugPrint(
      '[HighlightButton] Global highlighted stories: ${_stateManager.highlightedStoryIds}',
    );
    debugPrint(
      '[HighlightButton] Total highlights count: '
      '${_highlightController.highlights.length}',
    );
    debugPrint(
      '[HighlightButton] Is loading: ${_highlightController.isLoading.value}',
    );

    if (currentStoryId == null || currentStoryId.isEmpty) {
      debugPrint('[HighlightButton] No current story loaded yet');
      _matchedHighlight = null;
      _lastKnownHighlighted = false;
      return false;
    }

    // Check global state manager for highlighted story
    if (_stateManager.isStoryHighlighted(currentStoryId)) {
      debugPrint(
        '[HighlightButton] *** Story found in global state: $currentStoryId ***',
      );
      _lastKnownHighlighted = true;
      return true;
    }

    debugPrint('[HighlightButton] Story not found in global state');
    _matchedHighlight = null;
    _lastKnownHighlighted = false;
    return false;
  }

  Widget _buildHighlightIcon({
    required bool isHighlighted,
    required Color color,
  }) {
    if (isHighlighted) {
      return Icon(
        Icons.favorite,
        key: const ValueKey('highlight-filled-heart'),
        color: color,
        size: _highlightIconSize,
      );
    }

    return Icon(
      isHighlighted ? Icons.favorite : Icons.favorite_border,
      color: color,
      size: 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() {
            // Directly access reactive state to trigger UI rebuild
            final currentStoryId = _storyStateController.currentStory?.id
                ?.toString();
            final isHighlighted =
                currentStoryId != null &&
                _stateManager.isStoryHighlighted(currentStoryId);
            final buttonColor = isHighlighted ? _selectedColor : _inactiveColor;

            debugPrint(
              '[HighlightButton] isHighlighted: $isHighlighted, color: ${buttonColor.toString()}',
            );

            return GestureDetector(
              onTap: () {
                if (isHighlighted) {
                  final highlightName = _matchedHighlight?.title;
                  debugPrint(
                    '[HighlightButton] Tap ignored: already added'
                    '${highlightName == null ? '' : ' to $highlightName'}',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Already added to highlights'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                showInstagramHighlightSheet(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _buildHighlightIcon(
                      isHighlighted: isHighlighted,
                      color: buttonColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(color: buttonColor, fontSize: 12),
                    child: const Text('Highlight'),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(width: 30),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoreScreen()),
              );
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, color: Colors.white),
                SizedBox(height: 4),
                Text('More', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
