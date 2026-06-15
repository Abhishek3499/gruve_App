import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/features/highlights/controller/highlight_controller.dart';
import 'package:gruve_app/features/highlights/controller/highlight_state_manager.dart';
import 'package:gruve_app/features/highlights/model/highlight_model.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/model/story_model.dart';
import 'package:gruve_app/features/story_preview/screens/more_screen.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/highlight_sheet.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class StoryViewBottom extends StatefulWidget {
  final bool isOwnProfile;

  const StoryViewBottom({super.key, this.isOwnProfile = false});

  @override
  State<StoryViewBottom> createState() => _StoryViewBottomState();
}

class _StoryViewBottomState extends State<StoryViewBottom> {
  late final HighlightController _highlightController;
  late final StoryController _storyController;
  late final StoryStateController _storyStateController;
  late final HighlightStateManager _stateManager;

  HighlightModel? _matchedHighlight;
  bool _isPreparingHighlight = false;
  static const Color _inactiveColor = Colors.white;
  static const Color _selectedColor = AppColors.success;
  static const double _highlightIconSize = 24;

  @override
  void initState() {
    super.initState();
    _storyStateController = context.read<StoryStateController>();
    _storyController = context.read<StoryController>();
    _highlightController = context.read<HighlightController>();
    _stateManager = context.read<HighlightStateManager>();

    _storyStateController.addListener(_onStoryChanged);
    _stateManager.addListener(_onStoryChanged);

    // Only fetch highlights for own profile
    if (widget.isOwnProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_highlightController.highlights.isEmpty &&
            !_highlightController.isLoading) {
          _highlightController.fetchMyHighlights();
        }
      });
    }

    AppLogger.d(
      '[StoryViewBottom] initState - isOwnProfile: ${widget.isOwnProfile}',
    );
  }

  @override
  void dispose() {
    _storyStateController.removeListener(_onStoryChanged);
    _stateManager.removeListener(_onStoryChanged);
    super.dispose();
  }

  void _onStoryChanged() {
    if (mounted) {
      setState(() {
        _matchedHighlight = null;
      });
    }
  }

  Widget _buildHighlightIcon({
    required bool isHighlighted,
    required Color color,
  }) {
    if (_isPreparingHighlight) {
      return const SizedBox(
        key: ValueKey('highlight-loading'),
        width: _highlightIconSize,
        height: _highlightIconSize,
        child: CircularProgressIndicator(
          color: AppColors.loaderDark,
          strokeWidth: 2,
        ),
      );
    }

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

  Future<String?> _resolveCurrentStoryId() async {
    final currentStory = _storyStateController.currentStory;
    final currentId = currentStory?.id.trim();
    if (currentId != null && currentId.isNotEmpty) return currentId;

    if (currentStory == null) return null;

    AppLogger.d('[HighlightButton] Resolving missing story id');
    await _storyController.fetchStories(userId: null);

    if (!_storyController.isSuccess || _storyController.stories.isEmpty) {
      return null;
    }

    await _storyStateController.setStoriesFromStoryItems(
      _storyController.stories,
      username: _storyStateController.username,
      avatarUrl: _storyStateController.avatarUrl,
      userId: null,
    );

    final refreshedStory = _matchRefreshedStory(
      currentStory,
      _storyController.stories,
    );

    if (refreshedStory == null || refreshedStory.id.trim().isEmpty) {
      return null;
    }

    _storyStateController.setCurrentStory(refreshedStory);
    return refreshedStory.id;
  }

  StoryItem? _matchRefreshedStory(
    StoryItem currentStory,
    List<StoryItem> refreshedStories,
  ) {
    for (final story in refreshedStories) {
      if (story.mediaUrl == currentStory.mediaUrl) return story;
    }

    final localMedia = currentStory.mediaUrl.split('/').last.toLowerCase();
    for (final story in refreshedStories) {
      if (localMedia.isNotEmpty &&
          story.mediaUrl.toLowerCase().contains(localMedia)) {
        return story;
      }
    }

    return refreshedStories.isEmpty ? null : refreshedStories.first;
  }

  Future<void> _handleHighlightTap(bool isHighlighted) async {
    if (_isPreparingHighlight) return;

    if (isHighlighted) {
      final highlightName = _matchedHighlight?.title;
      AppLogger.d(
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

    setState(() => _isPreparingHighlight = true);

    try {
      final storyId = await _resolveCurrentStoryId();
      if (!mounted) return;

      if (storyId == null || storyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story is still syncing. Please try again shortly.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      AppLogger.d('[HighlightButton] Opening highlight sheet');
      showInstagramHighlightSheet(context);
    } catch (e) {
      AppLogger.d('[HighlightButton] Failed to prepare highlight sheet: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open highlights right now'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPreparingHighlight = false);
      }
    }
  }

  /// Build the Highlight button (only shown for own profile)
  Widget _buildHighlightButton() {
    if (!widget.isOwnProfile) {
      AppLogger.d('[StoryViewBottom] Highlight button hidden - not own profile');
      return const SizedBox.shrink();
    }

    return Builder(
      builder: (context) {
        final currentStoryId = _storyStateController.currentStory?.id
            .toString();
        final isHighlighted =
            currentStoryId != null &&
            _stateManager.isStoryHighlighted(currentStoryId);
        final buttonColor = isHighlighted ? _selectedColor : _inactiveColor;

        AppLogger.d(
          '[HighlightButton] isOwnProfile: ${widget.isOwnProfile}, '
          'isHighlighted: $isHighlighted, storyId: ${currentStoryId ?? 'null'}',
        );

        return GestureDetector(
          onTap: () => _handleHighlightTap(isHighlighted),
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
      },
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
          // Highlight button - only visible for own profile
          _buildHighlightButton(),
          // Only add spacing if highlight button is shown
          if (widget.isOwnProfile) const SizedBox(width: 30),
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
