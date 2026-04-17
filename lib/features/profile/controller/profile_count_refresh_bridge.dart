import 'package:flutter/foundation.dart';

class ProfileCountRefreshBridge {
  ProfileCountRefreshBridge._();

  static Future<void> Function(String reason)? onRefreshRequested;
  static bool _needsRefresh = false;

  static Future<void> notifyCountsChanged({
    String reason = 'unknown',
  }) async {
    debugPrint('🔔 Profile count refresh requested. reason=$reason');

    final callback = onRefreshRequested;
    if (callback != null) {
      _needsRefresh = false;
      await callback(reason);
      return;
    }

    _needsRefresh = true;
  }

  static bool consumePendingRefresh() {
    final needsRefresh = _needsRefresh;
    _needsRefresh = false;
    return needsRefresh;
  }

  static void clear() {
    onRefreshRequested = null;
    _needsRefresh = false;
  }
}
