import 'package:flutter/foundation.dart';

@immutable
class PostUploadProgressState {
  final bool isVisible;
  final double progress; // 0.0 to 100.0
  final bool isVideo;
  final String? mediaPath;
  final bool isCompleted;
  final bool isFailed;
  final String? errorMessage;

  const PostUploadProgressState({
    this.isVisible = false,
    this.progress = 0.0,
    this.isVideo = false,
    this.mediaPath,
    this.isCompleted = false,
    this.isFailed = false,
    this.errorMessage,
  });

  PostUploadProgressState copyWith({
    bool? isVisible,
    double? progress,
    bool? isVideo,
    String? mediaPath,
    bool? isCompleted,
    bool? isFailed,
    String? errorMessage,
  }) {
    return PostUploadProgressState(
      isVisible: isVisible ?? this.isVisible,
      progress: progress ?? this.progress,
      isVideo: isVideo ?? this.isVideo,
      mediaPath: mediaPath ?? this.mediaPath,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostUploadProgressState &&
        other.isVisible == isVisible &&
        other.progress == progress &&
        other.isVideo == isVideo &&
        other.mediaPath == mediaPath &&
        other.isCompleted == isCompleted &&
        other.isFailed == isFailed &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        isVisible,
        progress,
        isVideo,
        mediaPath,
        isCompleted,
        isFailed,
        errorMessage,
      );
}
