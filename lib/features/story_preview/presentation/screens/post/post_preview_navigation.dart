/// Returned when user taps **Next** on [PostPreviewScreen]; host pops camera
/// and presents [SharePostScreen] on the home stack.
class PostPreviewOpenShare {
  final String mediaPath;
  final String? mediaMimeType;

  const PostPreviewOpenShare(this.mediaPath, {this.mediaMimeType});
}

/// Returned when user taps the preview back button after capturing from camera.
/// The host can reopen the camera instead of falling back to the home feed.
class PostPreviewBackToCamera {
  const PostPreviewBackToCamera();
}
