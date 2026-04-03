class PostShareFlowBridge {
  // 🔥 EXISTING (dialog ke liye)
  static Function()? onShareStartProcessing;

  static void notifyShareStartProcessing() {
    if (onShareStartProcessing != null) {
      onShareStartProcessing!();
    }
  }

  // 🔥 NEW (optional future use)
  static Function()? onPostCreated;

  static void notifyPostCreated() {
    if (onPostCreated != null) {
      onPostCreated!();
    }
  }
}
