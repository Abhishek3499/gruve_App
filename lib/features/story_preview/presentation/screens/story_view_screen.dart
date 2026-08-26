import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gruve_app/core/constants/app_colors.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/utils/responsive_extensions.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/story_state_controller.dart';
import 'package:gruve_app/features/story_preview/domain/entities/story_model.dart';
import 'package:gruve_app/features/story_preview/presentation/controller/story_playback_controller.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_view_topbar/story_view_bottom.dart';
import 'package:gruve_app/features/story_preview/presentation/widgets/story_view_topbar/story_viewer_topbar.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class StoryViewScreen extends StatefulWidget {
  final String? userId;
  final List<String> mediaPaths;
  final String displayName;
  final String username;
  final String avatarUrl;
  final List<DateTime>? timestamps;
  final List<String?>? storyIds;
  final List<StoryItem>? storyItems;
  final bool isOwnProfile;

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
    this.isOwnProfile = false,
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

    AppLogger.d(
      '[StoryViewScreen] initState - isOwnProfile: ${widget.isOwnProfile}',
    );

    _storyStateController = context.read<StoryStateController>();

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
      AppLogger.d(
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
      AppLogger.d(
        '[StoryState] Unable to set currentStory: index=$currentIndex, '
        'stories=${widget.mediaPaths.length}, reason=$reason',
      );
      return;
    }

    _storyStateController.setCurrentStory(storyItem);
    AppLogger.d(
      '[Playback] story changed: index=$currentIndex, '
      'id=${storyItem.id.isEmpty ? 'MISSING' : storyItem.id}, reason=$reason',
    );
    AppLogger.d('[StoryState] current story media: ${storyItem.mediaUrl}');
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

    _videoController?.dispose();
    _videoController = null;

    final rawPath = widget.mediaPaths[currentIndex];
    final isLocal = File(rawPath).existsSync();

    String resolvedPath = rawPath;
    if (!isLocal && !rawPath.startsWith('http://') && !rawPath.startsWith('https://')) {
      final baseUrl = EnvironmentConfig.baseUrl.trim();
      if (baseUrl.isNotEmpty) {
        final baseUri = Uri.tryParse(baseUrl);
        if (baseUri != null) {
          final normalizedRelativePath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
          resolvedPath = baseUri.resolve(normalizedRelativePath).toString();
        }
      }
    }

    _isVideo =
        resolvedPath.toLowerCase().endsWith('.mp4') ||
        resolvedPath.toLowerCase().endsWith('.mov') ||
        resolvedPath.toLowerCase().endsWith('.avi');

    if (!_isVideo) {
      setState(() {
        _isImageLoading = !isLocal;
      });
    }

    if (_isVideo) {
      if (isLocal) {
        _videoController = VideoPlayerController.file(File(resolvedPath));
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(resolvedPath),
        );
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

    _animationController.reset();

    if (!_isVideo && _isImageLoading) {
      // Don't start the animation yet! It will be started when the image loads.
    } else {
      _animationController.forward();
    }

    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  void nextStory() {
    if (_isDisposed) return;

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

    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _syncCurrentStory(reason: 'previousStory');
      _initializeMedia();
    }
  }

  void _handleTap(TapUpDetails details) {
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
    final rawPath = widget.mediaPaths[currentIndex];
    final isLocal = File(rawPath).existsSync();

    String resolvedPath = rawPath;
    if (!isLocal && !rawPath.startsWith('http://') && !rawPath.startsWith('https://')) {
      final baseUrl = EnvironmentConfig.baseUrl.trim();
      if (baseUrl.isNotEmpty) {
        final baseUri = Uri.tryParse(baseUrl);
        if (baseUri != null) {
          final normalizedRelativePath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
          resolvedPath = baseUri.resolve(normalizedRelativePath).toString();
        }
      }
    }

    if (_isVideo && _videoController != null) {
      if (!_videoController!.value.isInitialized) {
        return const _StoryMediaLoader();
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

    if (!isLocal) {
      return Image.network(
        resolvedPath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            if (_isImageLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isImageLoading = false;
                  });
                  if (!_playbackController.isPaused) {
                    _animationController.forward();
                  }
                }
              });
            }
            return child;
          }
          return const _StoryMediaLoader();
        },
        errorBuilder: (context, error, stackTrace) {
          if (_isImageLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isImageLoading = false;
                });
                if (!_playbackController.isPaused) {
                  _animationController.forward();
                }
              }
            });
          }
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.file(
        File(resolvedPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _handleTap,
        onLongPressStart: (details) {
          AppLogger.d('[Playback] Long press detected');
          _pauseStory();
        },
        onLongPressEnd: (details) {
          AppLogger.d('[Playback] Long press released');
          _resumeStory();
        },
        onHorizontalDragEnd: _handleSwipe,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(child: _buildMedia()),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return StoryViewerTopBar(
                  username: widget.displayName.isNotEmpty
                      ? widget.displayName
                      : 'User',
                  time: _getCurrentStoryTime(),
                  avatarUrl: widget.avatarUrl.isNotEmpty
                      ? widget.avatarUrl
                      : 'https://i.pravatar.cc/150?img=3',
                  storyCount: widget.mediaPaths.length,
                  currentIndex: currentIndex,
                  progress: _animationController.value,
                  onClose: () => Navigator.pop(context),
                );
              },
            ),
            // Only show bottom bar for own profile stories
            if (widget.isOwnProfile)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: GestureDetector(
                    onTap: () {}, // Absorb taps to prevent skipping stories or popping screen
                    behavior: HitTestBehavior.opaque,
                    child: StoryViewBottom(isOwnProfile: widget.isOwnProfile),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoryMediaLoader extends StatelessWidget {
  const _StoryMediaLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: context.rw(28),
        height: context.rh(28),
        child: const CircularProgressIndicator(
          color: AppColors.loaderDark,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}
