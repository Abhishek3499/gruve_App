import 'package:gruve_app/core/media/video_frame_cache.dart';

/// 🎬 VideoPlaybackGuard
/// Coordinates video audio across the app so only ONE video plays audio at a time.
/// (e.g. Pauses background home reel when opening a video in Profile or Detail screen).
class VideoPlaybackGuard {
  VideoPlaybackGuard._();

  /// Callback to pause the active home feed reel
  static void Function()? pauseHomeFeed;

  /// Pauses home feed and other cached videos, activating only the requested video
  static Future<void> activateCacheVideo(String url) async {
    pauseHomeFeed?.call();
    await VideoFrameCache.pauseAll(activeUrl: url);
  }

  /// Stops and pauses all videos (e.g. when leaving screen)
  static Future<void> stopAll() async {
    pauseHomeFeed?.call();
    await VideoFrameCache.pauseAll();
  }
}
