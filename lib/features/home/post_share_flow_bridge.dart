/// Lets flows that are not awaited by [HomeScreen] (e.g. gallery → preview → share)
/// trigger the same post-share processing as the camera tab handler.
class PostShareFlowBridge {
  static void Function()? onShareStartProcessing;

  static void notifyShareStartProcessing() {
    onShareStartProcessing?.call();
  }
}
