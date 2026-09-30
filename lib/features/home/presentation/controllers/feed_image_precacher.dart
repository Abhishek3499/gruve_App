import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:gruve_app/core/utils/app_logger.dart';
import 'package:gruve_app/features/story_preview/domain/entities/post_model.dart';

/// Pre-caches feed poster/profile images so covers appear instantly while
/// videos buffer.
class FeedImagePrecacher {
  FeedImagePrecacher._();

  /// [allPosts] and [anchorIndex] are read synchronously at call time, same as
  /// the controller's previous inline implementation.
  static Future<void> precacheFeedImages(
    List<Post> posts, {
    required List<Post> allPosts,
    required int anchorIndex,
  }) async {
    final slice = posts.length <= 24 ? posts : posts.take(24).toList();
    final imageFutures = <Future<void>>[];

    for (final post in slice) {
      for (final imgUrl in [post.feedPosterUrl, post.profilePicture.trim()]) {
        final trimmed = imgUrl.trim();
        if (trimmed.isEmpty || !trimmed.startsWith('http')) continue;
        if (Post.mediaUrlLooksLikeVideo(trimmed)) continue;
        imageFutures.add(precacheNetworkImage(trimmed));
      }
    }

    // Posters for the next two slots — instant cover while video buffers.
    final anchor = anchorIndex;
    for (var offset = 1; offset <= 2; offset++) {
      final idx = anchor + offset;
      if (idx < 0 || idx >= allPosts.length) continue;
      final poster = allPosts[idx].feedPosterUrl.trim();
      if (poster.isEmpty || !poster.startsWith('http')) continue;
      if (Post.mediaUrlLooksLikeVideo(poster)) continue;
      imageFutures.add(precacheNetworkImage(poster));
    }

    final tasks = <Future<void>>[
      if (imageFutures.isNotEmpty) precacheImagesBatched(imageFutures),
    ];

    if (tasks.isEmpty) return;

    try {
      await Future.wait(tasks);
    } catch (e) {
      AppLogger.d('⚠️ Error pre-caching feed images: $e');
    }
  }

  static Future<void> precacheImagesBatched(List<Future<void>> futures) async {
    const batchSize = 12;
    for (var i = 0; i < futures.length; i += batchSize) {
      await Future.wait(futures.skip(i).take(batchSize));
    }
  }

  static Future<void> precacheNetworkImage(String imgUrl) async {
    final completer = Completer<void>();
    final provider = CachedNetworkImageProvider(imgUrl);
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (exception, stackTrace) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
  }
}
