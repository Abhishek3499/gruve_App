import 'dart:async';

import 'package:gruve_app/core/utils/app_logger.dart';

class ProfileCountRefreshBridge {
  ProfileCountRefreshBridge._();

  static Future<void> Function(String reason)? onRefreshRequested;
  static bool _needsRefresh = false;
  static Timer? _debounceTimer;
  static String? _pendingReason;
  static const _debounceDuration = Duration(milliseconds: 1500);

  static Future<void> notifyCountsChanged({
    String reason = 'unknown',
  }) async {
    AppLogger.d('🔔 Profile count refresh requested. reason=$reason');

    final callback = onRefreshRequested;
    if (callback == null) {
      _needsRefresh = true;
      return;
    }

    _pendingReason = reason;
    _debounceTimer?.cancel();
    final completer = Completer<void>();
    _debounceTimer = Timer(_debounceDuration, () async {
      final pending = _pendingReason ?? reason;
      _pendingReason = null;
      _needsRefresh = false;
      try {
        await callback(pending);
        if (!completer.isCompleted) completer.complete();
      } catch (e, st) {
        AppLogger.d('⚠️ Profile count refresh failed: $e\n$st');
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  static bool consumePendingRefresh() {
    final needsRefresh = _needsRefresh;
    _needsRefresh = false;
    return needsRefresh;
  }

  static void clear() {
    onRefreshRequested = null;
    _needsRefresh = false;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingReason = null;
  }
}
