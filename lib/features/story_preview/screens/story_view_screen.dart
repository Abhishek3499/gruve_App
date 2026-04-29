import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';
import 'package:gruve_app/features/story_preview/api/story_api/model/story_model.dart';
import 'package:gruve_app/features/story_preview/controllers/story_playback_controller.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_view_bottom.dart';
import 'package:gruve_app/features/story_preview/widgets/story_view_topbar/story_viewer_topbar.dart';
import 'package:video_player/video_player.dart';

class StoryViewScreen extends StatefulWidget {
  final String? userId;
  final List<String> mediaPaths;
  final String displayName;
  final String username;
  final String avatarUrl;
  final List<DateTime>? timestamps;
  final List<String?>? storyIds;
  final List<StoryItem>? storyItems;

  const StoryViewScreen({
    super.key,
    this.userId,
    required this.mediaPaths,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    this.timestamps,
    this.storyIds,
    this.storyItems,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late final StoryStateController _storyStateController;

  int currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isDisposed = false;
  AnimationStatusListener? _animationListener;
  bool _isImageLoading = false;

  final StoryPlaybackController _playbackController = StoryPlaybackController();

  @override
  void initState() {
    super.initState();

    StoryStateController.ensureRegistered();
    _storyStateController = Get.find<StoryStateController>();

    _playbackController.initialize();
    _initializeCurrentStory();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animationListener = (status) {
      if (status == AnimationStatus.completed &&
          !_isDisposed &&
          !_playbackController.isPaused) {
        nextStory();
      }
    };
    _animationController.addStatusListener(_animationListener!);
    _playbackController.addListener(_onPlaybackStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMedia();
    });
  }

  void _initializeCurrentStory() {
    _syncCurrentStory(reason: 'init');
  }

  StoryItem? _storyItemForIndex(int index) {
    if (index < 0 || index >= widget.mediaPaths.length) return null;

    if (widget.storyItems != null && index < widget.storyItems!.length) {
      return widget.storyItems![index];
    }

    final mediaPath = widget.mediaPaths[index];
    final storyId = widget.storyIds != null && index < widget.storyIds!.length
        ? widget.storyIds![index]
        : _storyStateController.getStoryIdByMediaPath(mediaPath);
    final createdAt =
        widget.timestamps != null && index < widget.timestamps!.length
            ? widget.timestamps![index]
            : DateTime.now();

    if (storyId == null || storyId.isEmpty) {
      debugPrint(
        '[StoryState] Missing story id for media=$mediaPath at index=$index',
      );
    }

    return StoryItem(
      id: storyId ?? '',
      mediaUrl: mediaPath,
      mediaMimeType: _getMimeTypeFromPath(mediaPath),
      mediaKind: _getMediaKindFromPath(mediaPath),
      createdAt: createdAt,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      userId: widget.userId ?? 'me',
      username: widget.username,
      avatarUrl: widget.avatarUrl,
    );
  }

  String _getMimeTypeFromPath(String mediaPath) {
    final lowerPath = mediaPath.toLowerCase();
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.gif')) return 'image/gif';
    if (lowerPath.endsWith('.mp4')) return 'video/mp4';
    if (lowerPath.endsWith('.mov')) return 'video/quicktime';
    if (lowerPath.endsWith('.avi')) return 'video/x-msvideo';
    return 'application/octet-stream';
  }

  String _getMediaKindFromPath(String mediaPath) {
    final lowerPath = mediaPath.toLowerCase();
    if (lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi')) {
      return 'video';
    }
    return 'image';
  }

  void _syncCurrentStory({required String reason}) {
    final storyItem = _storyItemForIndex(currentIndex);

    if (storyItem == null) {
      debugPrint(
        '[StoryState] Unable to set currentStory: index=$currentIndex, '
        'stories=${widget.mediaPaths.length}, reason=$reason',
      );
      return;
    }

    _storyStateController.setCurrentStory(storyItem);
    debugPrint(
      '[Playback] story changed: index=$currentIndex, '
      'id=${storyItem.id.isEmpty ? 'MISSING' : storyItem.id}, reason=$reason',
    );
    debugPrint('[StoryState] current story media: ${storyItem.mediaUrl}');
  }

  void _onPlaybackStateChanged() {
    if (_isDisposed) return;

    if (_playbackController.isPaused) {
      _pauseAnimationAndVideo();
    } else {
      _resumeAnimationAndVideo();
    }
  }

  Future<void> _initializeMedia() async {
    if (_isDisposed) return;

    if (!_isVideo) {
      setState(() {
        _isImageLoading = true;
      });
    }

    _videoController?.dispose();
    _videoController = null;

    final mediaPath = widget.mediaPaths[currentIndex];
    _isVideo = mediaPath.toLowerCase().endsWith('.mp4') ||
        mediaPath.toLowerCase().endsWith('.mov') ||
        mediaPath.toLowerCase().endsWith('.avi');

    if (_isVideo) {
      if (mediaPath.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(mediaPath),
        );
      } else {
        _videoController = VideoPlayerController.file(File(mediaPath));
      }

      await _videoController!.initialize();

      if (_isDisposed) {
        _videoController?.dispose();
        return;
      }

      _videoController!.play();
      _videoController!.setLooping(true);
      _animationController.duration = _videoController!.value.duration;
    } else {
      _animationController.duration = const Duration(seconds: 5);
    }

    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  void nextStory() {
    if (_isDisposed) return;

    if (_isImageLoading && !_isVideo) {
      debugPrint('[Playback] Cannot navigate - image still loading');
      return;
    }

    if (currentIndex < widget.mediaPaths.length - 1) {
      setState(() => currentIndex++);
      _syncCurrentStory(reason: 'nextStory');
      _initializeMedia();
    } else {
      if (mounted && !_isDisposed) {
        Navigator.pop(context);
      }
    }
  }

  void previousStory() {
    if (_isDisposed) return;

    if (_isImageLoading && !_isVideo) {
      debugPrint('[Playback] Cannot navigate - image still loading');
      return;
    }

    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _syncCurrentStory(reason: 'previousStory');
      _initializeMedia();
    }
  }

  void _handleTap(TapUpDetails details) {
    if (_isImageLoading && !_isVideo) {
      debugPrint('[Playback] Cannot navigate - image still loading');
      return;
    }

    final width = MediaQuery.of(context).size.width;

    if (details.globalPosition.dx > width / 2) {
      nextStory();
    } else {
      previousStory();
    }
  }

  void _pauseStory() {
    _playbackController.pauseStory(reason: 'Long Press');
  }

  void _resumeStory() {
    _playbackController.resumeStory(reason: 'Long Press Release');
  }

  void _pauseAnimationAndVideo() {
    _animationController.stop();
    _videoController?.pause();
  }

  void _resumeAnimationAndVideo() {
    _animationController.forward();
    _videoController?.play();
  }

  void _handleSwipe(DragEndDetails details) {
    if (_isImageLoading && !_isVideo) {
      debugPrint('[Playback] Cannot navigate - image still loading');
      return;
    }

    final velocity = details.primaryVelocity ?? 0;

    if (velocity < 0) {
      nextStory();
    } else if (velocity > 0) {
      previousStory();
    }
  }

  String _getCurrentStoryTime() {
    if (widget.timestamps != null && currentIndex < widget.timestamps!.length) {
      final diff = DateTime.now().difference(widget.timestamps![currentIndex]);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return '4h';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _playbackController.removeListener(_onPlaybackStateChanged);
    _playbackController.reset();
    _videoController?.dispose();
    if (_animationListener != null) {
      _animationController.removeStatusListener(_animationListener!);
    }
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildMedia() {
    final path = widget.mediaPaths[currentIndex];

    if (_isVideo && _videoController != null) {
      if (!_videoController!.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            if (_isImageLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isImageLoading = false;
                  });
                }
              });
            }
            return child;
          }
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (_isImageLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isImageLoading = false;
                });
              }
            });
          }
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      final fileImage = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (_isImageLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isImageLoading = false;
                });
              }
            });
          }
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );

      fileImage.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool synchronousCall) {
          if (_isImageLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isImageLoading = false;
                });
              }
            });
          }
        }),
      );

      return fileImage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _handleTap,
        onLongPressStart: (details) {
          debugPrint('[Playback] Long press detected');
          _pauseStory();
        },
        onLongPressEnd: (details) {
          debugPrint('[Playback] Long press released');
          _resumeStory();
        },
        onHorizontalDragEnd: _handleSwipe,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(child: _buildMedia()),
            StoryViewerTopBar(
              username:
                  widget.displayName.isNotEmpty ? widget.displayName : 'User',
              time: _getCurrentStoryTime(),
              avatarUrl: widget.avatarUrl.isNotEmpty
                  ? widget.avatarUrl
                  : 'https://i.pravatar.cc/150?img=3',
              storyCount: widget.mediaPaths.length,
              currentIndex: currentIndex,
              progress: _animationController.value,
              onClose: () => Navigator.pop(context),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(top: false, child: const StoryViewBottom()),
            ),
          ],
        ),
      ),
    );
  }
}
