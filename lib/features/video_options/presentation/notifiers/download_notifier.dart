import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/services/media_download_service.dart';

/// Immutable state for [DownloadNotifier]: which ids currently have a
/// media download in flight.
@immutable
class DownloadState {
  const DownloadState({this.downloadingIds = const {}});

  final Set<String> downloadingIds;

  bool isDownloading(String id) => downloadingIds.contains(id);

  DownloadState copyWith({Set<String>? downloadingIds}) {
    return DownloadState(downloadingIds: downloadingIds ?? this.downloadingIds);
  }
}

class DownloadNotifier extends Notifier<DownloadState> {
  @override
  DownloadState build() => const DownloadState();

  /// Downloads the media at [url] straight into the device gallery.
  ///
  /// [id] identifies the in-flight download (typically the post id) so
  /// repeated taps while a download is running are ignored. [isVideo]
  /// selects whether the media is saved as a video or an image.
  Future<void> downloadMedia(
    String id,
    String url, {
    required bool isVideo,
  }) async {
    if (state.isDownloading(id)) return;

    state = state.copyWith(downloadingIds: {...state.downloadingIds, id});
    try {
      if (isVideo) {
        await MediaDownloadService.downloadVideoToGallery(url);
      } else {
        await MediaDownloadService.downloadImageToGallery(url);
      }
    } finally {
      state = state.copyWith(
        downloadingIds: {...state.downloadingIds}..remove(id),
      );
    }
  }
}

final downloadNotifierProvider =
    NotifierProvider<DownloadNotifier, DownloadState>(DownloadNotifier.new);
