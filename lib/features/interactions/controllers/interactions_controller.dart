import 'package:flutter/material.dart';

/// Interactions screen controller
class InteractionsController extends ChangeNotifier {
  int _selectedTab = 0;
  static const List<String> _tabs = ['All', 'Followers', 'Non-followers'];

  int get selectedTab => _selectedTab;
  List<String> get tabs => _tabs;

  void selectTab(int index) {
    if (index >= 0 && index < _tabs.length && index != _selectedTab) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  bool isTabActive(int index) {
    return _selectedTab == index;
  }
}
