import 'package:flutter/foundation.dart';

class HighlightFlowProvider extends ChangeNotifier {
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  void setProcessing(bool value) {
    if (_isProcessing == value) return;
    _isProcessing = value;
    notifyListeners();
  }

  /// Reset highlight flow state on logout
  void reset() {
    debugPrint('🔄 [HighlightFlowProvider] Resetting highlight flow...');
    _isProcessing = false;
    notifyListeners();
    debugPrint('✅ [HighlightFlowProvider] Highlight flow reset complete');
  }
}
