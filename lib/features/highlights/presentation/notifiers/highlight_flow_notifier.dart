import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class HighlightFlowNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  bool get isProcessing => state;

  void setProcessing(bool value) {
    if (state == value) return;
    state = value;
  }

  /// Reset highlight flow state on logout
  void reset() {
    AppLogger.d('🔄 [HighlightFlowNotifier] Resetting highlight flow...');
    state = false;
    AppLogger.d('✅ [HighlightFlowNotifier] Highlight flow reset complete');
  }
}

final highlightFlowNotifierProvider =
    NotifierProvider<HighlightFlowNotifier, bool>(HighlightFlowNotifier.new);
