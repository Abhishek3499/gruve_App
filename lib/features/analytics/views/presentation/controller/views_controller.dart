import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

/// Views screen controller
class ViewsController extends ChangeNotifier {
  int _selectedTab = 0;
  static const List<String> _tabs = ['All', 'Followers', 'Non-followers'];

  int get selectedTab => _selectedTab;
  List<String> get tabs => _tabs;

  void selectTab(int index) {
    if (index >= 0 && index < _tabs.length && index != _selectedTab) {
      AppLogger.d("[ViewsController] Tab changed to: ${_tabs[index]}");
      _selectedTab = index;
      notifyListeners();
    }
  }

  bool isTabActive(int index) {
    return _selectedTab == index;
  }
}
