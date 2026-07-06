# Codebase Audit Summary Report

Scanned **494** Dart files. Found **317** issues across **127** files.

## Issues by Category

- **Memory Leak**: 37 issues
- **Architecture Violation**: 232 issues
- **Performance**: 30 issues
- **Memory Leak / Crash Risk**: 18 issues

## Top Critical and High Severity Issues

### Critical: Memory Leak in `lib\screens\splash_screen.dart` (Line 38)
- **Issue**: Variable 'asset' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `_controller = VideoPlayerController.asset(AppAssets.splashVideo);`

### High: Memory Leak / Crash Risk in `lib\features\video_editor\screens\video_editor_screen.dart` (Line 166)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {`

### Critical: Memory Leak in `lib\features\video_editor\screens\video_editor_screen.dart` (Line 47)
- **Issue**: Variable '_videoController' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _videoController;`

### Critical: Memory Leak in `lib\features\story_preview\providers\share_post_provider.dart` (Line 6)
- **Issue**: Variable '_videoController' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _videoController;`

### Critical: Memory Leak in `lib\features\story_preview\providers\share_post_provider.dart` (Line 22)
- **Issue**: Variable 'get' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? get videoController => _videoController;`

### High: Memory Leak / Crash Risk in `lib\features\story_preview\screens\story_preview_screen.dart` (Line 596)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {`

### Critical: Memory Leak in `lib\features\story_preview\screens\story_preview_screen.dart` (Line 44)
- **Issue**: Variable '_videoController' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _videoController;`

### Critical: Memory Leak in `lib\features\story_preview\screens\story_view_screen.dart` (Line 49)
- **Issue**: Variable '_videoController' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _videoController;`

### High: Memory Leak / Crash Risk in `lib\features\story_preview\screens\post\post_preview_screen.dart` (Line 416)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {`

### Critical: Memory Leak in `lib\features\story_preview\screens\post\post_preview_screen.dart` (Line 40)
- **Issue**: Variable '_videoController' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _videoController;`

### High: Memory Leak / Crash Risk in `lib\features\story_preview\screens\post\share_post_screen.dart` (Line 553)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {`

### Critical: Memory Leak in `lib\features\story_preview\screens\post\share_post_screen.dart` (Line 61)
- **Issue**: Variable '_videoController' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _videoController;`

### Critical: Memory Leak in `lib\features\story_preview\screens\post\share_post_screen.dart` (Line 82)
- **Issue**: Variable 'text' of type 'TextEditingController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `captionController = TextEditingController(text: widget.initialCaption);`

### High: Memory Leak / Crash Risk in `lib\features\story_preview\screens\post\tag_people_screen.dart` (Line 146)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {`

### Critical: Memory Leak in `lib\features\search\widgets\explore_reels_grid.dart` (Line 26)
- **Issue**: Variable '_scrollController' of type 'ScrollController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `final ScrollController _scrollController = ScrollController();`

### Critical: Memory Leak in `lib\features\profile_menu_drawer\screens\post_detail_screen.dart` (Line 28)
- **Issue**: Variable '_videoControllers' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `late Map<int, VideoPlayerController?> _videoControllers;`

### Critical: Memory Leak in `lib\features\profile_menu_drawer\screens\post_detail_screen.dart` (Line 34)
- **Issue**: Variable 'initialPage' of type 'PageController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `_pageController = PageController(initialPage: _currentIndex);`

### Critical: Memory Leak in `lib\features\profile_menu_drawer\screens\post_detail_screen.dart` (Line 45)
- **Issue**: Variable 'networkUrl' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `final controller = VideoPlayerController.networkUrl(`

### High: Memory Leak / Crash Risk in `lib\features\profile\screens\post_detail\profile_post_detail_screen.dart` (Line 197)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `if (mounted) setState(() {});`

### High: Memory Leak / Crash Risk in `lib\features\profile\screens\post_detail\profile_post_detail_screen.dart` (Line 217)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {`

### Critical: Memory Leak in `lib\features\profile\screens\post_detail\profile_post_detail_screen.dart` (Line 51)
- **Issue**: Variable '_videoControllers' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `final Map<int, VideoPlayerController?> _videoControllers = {};`

### Critical: Memory Leak in `lib\features\profile\screens\post_detail\profile_post_detail_screen.dart` (Line 61)
- **Issue**: Variable 'initialPage' of type 'PageController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `_pageController = PageController(initialPage: _currentIndex);`

### Critical: Memory Leak in `lib\features\message\screen\fullscreen_media_viewer.dart` (Line 22)
- **Issue**: Variable '_videoController' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _videoController;`

### Critical: Memory Leak in `lib\features\message\screen\fullscreen_media_viewer.dart` (Line 40)
- **Issue**: Variable 'file' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `_videoController = VideoPlayerController.file(File(path));`

### Critical: Memory Leak in `lib\features\message\screen\fullscreen_media_viewer.dart` (Line 42)
- **Issue**: Variable 'networkUrl' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `_videoController = VideoPlayerController.networkUrl(Uri.parse(path));`

### Critical: Memory Leak in `lib\features\message\widgets\chat_bubble.dart` (Line 597)
- **Issue**: Variable '_controller' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _controller;`

### High: Memory Leak / Crash Risk in `lib\features\message\widgets\chat_input_field.dart` (Line 356)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {`

### High: Memory Leak / Crash Risk in `lib\features\message\widgets\chat_input_field.dart` (Line 371)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {`

### High: Memory Leak / Crash Risk in `lib\features\message\widgets\voice_message_player.dart` (Line 240)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {`

### Critical: Memory Leak in `lib\features\message\widgets\voice_message_player.dart` (Line 21)
- **Issue**: Variable '_activePlayer' of type 'AudioPlayer' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `static AudioPlayer? _activePlayer;`

### Critical: Memory Leak in `lib\features\home\widgets\video_feed.dart` (Line 420)
- **Issue**: Variable '_animController' of type 'AnimationController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `late AnimationController _animController;`

### Critical: Memory Leak in `lib\features\home\widgets\video_feed.dart` (Line 861)
- **Issue**: Variable '_boundController' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _boundController;`

### Critical: Memory Leak in `lib\features\highlights\screens\highlight_viewer_screen.dart` (Line 34)
- **Issue**: Variable '_progressController' of type 'AnimationController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `late final AnimationController _progressController;`

### Critical: Memory Leak in `lib\features\highlights\screens\highlight_viewer_screen.dart` (Line 696)
- **Issue**: Variable '_videoController' of type 'VideoPlayerController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `VideoPlayerController? _videoController;`

### High: Memory Leak / Crash Risk in `lib\features\comments\widgets\comment_sheet.dart` (Line 49)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() => _isLoading = true);`

### Critical: Memory Leak in `lib\features\camera\screen\camera_screen.dart` (Line 339)
- **Issue**: Variable '_zoomAnimationController' of type 'AnimationController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `late final AnimationController _zoomAnimationController;`

### High: Memory Leak / Crash Risk in `lib\features\camera\widgets\capture_button.dart` (Line 157)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {});`

### High: Memory Leak / Crash Risk in `lib\features\camera\widgets\horizontal_filter_selector.dart` (Line 268)
- **Issue**: setState() called after await without checking if the widget is still mounted.
- **Code**: `setState(() {});`

### Critical: Memory Leak in `lib\features\auth\screens\otp_screen.dart` (Line 81)
- **Issue**: Variable '_controllers' of type 'TextEditingController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `final List<TextEditingController> _controllers = List.generate(`

### Critical: Memory Leak in `lib\features\Account\screens\account_screen.dart` (Line 41)
- **Issue**: Variable 'text' of type 'TextEditingController' is declared in a State/ChangeNotifier class but not disposed in dispose().
- **Code**: `_nameController = TextEditingController(text: '');`

