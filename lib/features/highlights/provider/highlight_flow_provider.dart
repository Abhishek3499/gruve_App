import 'package:flutter/foundation.dart';

class HighlightFlowProvider extends ChangeNotifier {
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  void setProcessing(bool value) {
    if (_isProcessing == value) return;
    _isProcessing = value;
    notifyListeners();
  }
}
