import 'package:gruve_app/core/media/video_frame_cache.dart';

/// Coordinates exclusive audio across home feed and grid/detail players.
class VideoPlaybackGuard {
  VideoPlaybackGuard._();

  static void Function()? pauseHomeFeed;

  static Future<void> activateCacheVideo(String url) async {
    pauseHomeFeed?.call();
    await VideoFrameCache.pauseAll(activeUrl: url);
  }

  static Future<void> stopAll() async {
    pauseHomeFeed?.call();
    await VideoFrameCache.pauseAll();
  }
}
