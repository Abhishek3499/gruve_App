/// Returned when user taps **Next** on [PostPreviewScreen]; host pops camera
/// and presents [SharePostScreen] on the home stack.
class PostPreviewOpenShare {
  final String mediaPath;

  const PostPreviewOpenShare(this.mediaPath);
}
